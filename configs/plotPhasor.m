function plotPhasor(complexNumber)

    # ploteo un fasor dado como numero complejo en cartesianas

    # obtengo el fasor a partir del numero complejo en cartesiano
    [magnitude, phase] = phasor(complexNumber);

    # paso a radianes los grados
    phase = deg2rad(phase);

    polar([0, phase], [0, magnitude]);

end
