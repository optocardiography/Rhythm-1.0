function phaseMap(data,directory,starttime,endtime,Fs)

% Email optocardiography@gmail.com for any questions or concerns.
% Refer to efimovlab.org for more information.

    movname = [directory,'/','phasemovie' '.avi'];
    vidObj = avifile(movname,'compression','None');
    data = data(:,:,round(starttime*Fs+1):round(endtime*Fs));
    temp = reshape(data,[],size(data,3))' - repmat(mean(reshape(data,[],size(data,3))'),size(data,3),1);
    hdata = hilbert(temp);
    phase = -1*angle(hdata)';
    phase = reshape(phase,size(data,1),size(data,2),[]);
    fig = figure;
    for i = 1:size(data,3)
        imagesc(phase(:,:,i))
        colorbar
        caxis([-pi pi])
        axis image
        axis off
        pause(.001)
        F = getframe(fig);
        vidObj = addframe(vidObj,F);
    end
    close(fig);
    vidObj=close(vidObj); % Close the file.
end