function [ GSWYields ] = GSWParams2Yields( GSWParams )
%GSWParams2Yields converts GSW parameters to GSW yields. 
%   
    maturities          = ((1:360) / 12)';
    beta                = GSWParams(:,1:4);
    tau1                = 1 ./ GSWParams(:,5)*maturities';
    tau2                = 1 ./ GSWParams(:,6)*maturities';
    exptau1             = -exp(-tau1);
    exptau2             = -exp(-tau2);

    Lambda_ylds         = ones(size(GSWParams,1), length(maturities),4);
    Lambda_ylds(:,:,2)  = (1+exptau1)./(tau1);
    Lambda_ylds(:,:,3)  = Lambda_ylds(:,:,2) + exptau1;
    Lambda_ylds(:,:,4)  = (1+exptau2) ./ tau2 + exptau2;
    GSWYields           = tprod(Lambda_ylds, [1 2 -1], beta, [1 -1]);

end
