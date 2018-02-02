function cmosData = CMOSconverter(olddir,oldfilename)
% Email optocardiography@gmail.com for any questions or concerns.
% Refer to efimovlab.org for more information.
x2rot = 0;
flip = 0;
newfilename = [oldfilename(1:length(oldfilename)-3),'mat'];
dirname = [olddir,'/'];
% Read the file
% Read the file

        disp(['converting ',oldfilename])
        fid=fopen([dirname,oldfilename],'r','b');        
        fstr=fread(fid,'int8=>char')';
        fclose(fid);
        sampind2=strfind(fstr,'msec');
        sampind1=find(fstr(1:sampind2(1))==' ',1,'last');
        r=str2double(fstr(sampind1+1:sampind2(1)-1));%ratio of optical and analog samle rate
        
        %save the frequency to put in the .m file
        frequency = 1000.0 / r;
        
        % locate the Data-File-List
        Dindex = find(fstr == 'D');
        for i = 1:length(Dindex)
            if isequal(fstr(Dindex(i):Dindex(i)+13),'Data-File-List')
                origin = Dindex(i)+14+2; % there are two blank char between each line
                break;
            end
        end

        % Save the data file paths
        len = length(fstr);
        N = 1000;  % assume file list < 1000 files
        dataPaths = cell(N,1);
        pointer = origin;
        %{
        while ~isequal(fstr(pointer:pointer+3),'.rsm')
            pointer = pointer + 1;
        end
        dataPaths{1,1} = fstr(origin:pointer+3);
        origin = pointer + 4 + 2;
        %}
        seq = 0;
        while origin<len
            seq = seq+1;
            pointer = origin;
            while (strcmp(fstr(pointer:pointer+3),'.rsd') || strcmp(fstr(pointer:pointer+3),'.rsm'))==0
                pointer = pointer + 1;
            end
            dataPaths{seq,1} = fstr(origin:pointer+3);%-+1
            origin = pointer+4+2;
        end
        dataPaths = dataPaths(1:seq);
        % Read CMOS data
        %h = fir1(50,250/fs);   % fs is the sampling frequncy; change filtering frequency here. 
        num = length(dataPaths);
        cmosData = int32(zeros(100,100,(num-1)*256));
        orgFrame = int32(zeros(100,100));
        channel1 = nan(1,(num-1)*256*r);
        channel2 = nan(1,(num-1)*256*r);
        k=1;
        for i = 2:num
            fpath = [dirname dataPaths{i}];
            fid=fopen(fpath,'r','l');       % use big-endian format
            fdata=fread(fid,'int16=>int32')'; %
            fclose(fid);
            fdata = reshape(fdata,12800,[]);
            %if i == 2 %assumes 1st .rsd file is 2nd file (.rsm is 1st)
            %    fdata(:,1) = fdata(:,2);
            %end
            for j = 1:size(fdata,2)
                oneframe = fdata(:,j);  % one frame at certain time point
                oneframe = reshape(oneframe,128,100);
                cmosData(:,:,k) = oneframe(21:120,:)';
                if r==1
                    channel1(k) = oneframe(13,1);%needs to be improved
                    channel2(k) = oneframe(15,1);
                elseif r==2
                    channel1(2*k-1:2*k) = [oneframe(13,1);oneframe(13,5)];
                    channel2(2*k-1:2*k) = [oneframe(15,1);oneframe(15,5)];
                else
                    disp('problem converting channels')
                end
                k=k+1;
            end
            clear fdata;
        end

        % based on the assumption that the upstroke is downward, not upward.
        len = size(cmosData,3);
        thred = 2^16*3/4;
        for i = 1:100
            for j = 1:100
                temp = cmosData(i,j,:);
                for k = 3:len %skip 1st frame, which is bg image, and 2nd frame, which is copy of 1st
                    if abs(temp(k)-temp(k-1))>thred
                        if temp(k)>0
                            temp(k)=temp(k)-2^16;
                        else
                            temp(k)=2^16+temp(k);
                        end
                    end
                end
                cmosData(i,j,:) = -temp;
            end
        end     
        for r=1:x2rot
            for i=1:size(cmosData,3)
                cmosData(:,:,i)=rot90(cmosData(:,:,i));
            end
        end
        if flip~=0
            cmosData=flipdim(cmosData,flip);
        end
        newfilename = [olddir,'/',newfilename];
        
        
        bgimage = -1 * cmosData(:,:,1);
        
        %bgimage = int16(scaledata(double(bgimage),0,255));
        
        save(newfilename,'cmosData','channel1','channel2','r', 'frequency', 'bgimage');
end