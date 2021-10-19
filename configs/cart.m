function [complexNumber] = cart(magnitude, phase)

    # devuelvo un numero complejo en cartesianas a partir de un fasor
    # se espera una fase en grados

    complexNumber = NaN;

    # paso a radianes los grados
    phase = deg2rad(phase);

    [r, ima] = pol2cart(phase, magnitude);

    complexNumber = r + ima*i;

end
