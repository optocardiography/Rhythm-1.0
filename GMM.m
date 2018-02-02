function logl = GMM(APD_vect,grps,options)
% Email optocardiography@gmail.com for any questions or concerns.
% Refer to efimovlab.org for more information.
obj = gmdistribution.fit(APD_vect,grps,'Options',options);
logl = obj.NlogL;
end