function [s1, s2] = bhaskara(a, b, c)

    %funcion que devuelve las dos soluciones numericas de la formula de bhaskara
    %a, b y c son los coeficientes de la formula

    s1 = NaN;
    s1 = NaN;

    numerator1 = - b + sqrt(b**2-4*c*a);
    numerator2 = - b - sqrt(b**2-4*c*a);
    denominator = 2*a;

    s1 = numerator1/denominator;
    s2 = numerator2/denominator;

end
