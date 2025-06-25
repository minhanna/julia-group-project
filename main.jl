# Datenstruktur zur Verwaltung von Voronoi-Diagrammen
struct Punkt
    x::Float64 
    y::Float64
end

abstract type Face end
mutable struct Kante
    origin::Punkt
    twin::Kante
    next::Kante
    prev::Kante
    face::Face
end

mutable struct Dreieck <: Face
    edge::Kante
end

mutable struct Delaunay
    triangles::Set{Dreieck}
    bounding_triangle::Dreieck
end

# Delaunay-Algorithmus

# Prüfe, ob Umkreis (der Kante e enthält) Delaunay-Eigenschaft erfüllt
function check_umkreis(e::Kante)::Bool
    # Dreieck abc mit Kante e
    a = e.origin
    b = e.next.origin
    c = e.prev.origin

    # d Ecke des rechten Nachbardreieck e.twin
    d = _opposite_edge(e)

    A = [a.x  a.y  a.x^2+a.y^2  1;
         b.x  b.y  b.x^2+b.y^2  1;
         c.x  c.y  c.x^2+c.y^2  1;
         d.x  d.y  d.x^2+d.y^2  1]

    if det(A) > 0
        return true
    end
    return false
end

# Hilfsfunktion um sicherzustellen, dass d kein Eckpunkt von e
function _opposite_edge(e::Kante)::Punkt 
    a = e.origin
    b = e.next.origin

    for p in [e.twin.origin, e.twin.next.origin, e.twin.next.next.origin] # Einer von ihnen NICHT a oder b -> d
        if p != a && p != b
            return p
        end
    end
end

function flip!(e::Kante, D::Delaunay) # fiebertraum
    # Alte Dreiecke
    t1 = e.face
    t2 = e.twin.face

    # Eckpunkte
    a, b = e.origin, e.twin.origin
    c, d = e.next.origin, e.twin.next.origin

    # Hilfskanten
    e1 = e.next        # von b nach c
    e2 = e.prev        # von c nach a
    e3 = e.twin.next   # von a nach d
    e4 = e.twin.prev   # von d nach b

    # Neue Kanten 
    cd, dc = e, e.twin
    cd.origin, dc.origin = c, d

    # Kantenverbindungen für neues Dreieck cdb aktualisieren (pretty much im Kreis laufen)
    cd.next, e4.prev = e4, cd
    e4.next, e1.prev = e1, e4
    e1.next, cd.prev = cd, e1 

    # Kantenverbindungen für neues Dreieck dca aktualisieren
    dc.next, e2.prev = e2, dc
    e2.next, e3.prev = e3, e2
    e3.next, dc.prev = dc, e3

    # neue Dreiecke
    new_t1 = Dreieck(cd)
    new_t2 = Dreieck(dc)

    cd.face, e4.face, e1.face = new_t1, new_t1, new_t1 # Jeder Kante ihre neue Fläche zuweisen
    dc.face, e2.face, e3.face = new_t2, new_t2, new_t2

    # Triangulierungen aktualisieren
    delete!(D.triangles, t1)
    delete!(D.triangles, t2)
    push!(D.triangles, new_t1)
    push!(D.triangles, new_t2)
end

function recursive_flip!(e::Kante, D::Delaunay)
    if check_umkreis(e)
        p = _opposite_edge(e)
        flip!(e,D)
        recursive_flip!(e.prev,D) # ap ist e.prev
        recursive_flip!(e.next,D) # pb ist e.next
    end
end

# Für Insert brauch ich erstmal find_triangle 
function _triangle_area(a::Punkt, b::Punkt, c::Punkt)::Float64
    return abs((a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2.0)
end

function _point_in_triangle(p::Punkt, a::Punkt, b::Punkt, c::Punkt)::Bool # Idee aus geekforgeeks...
    A = triangle_area(a, b, c)
    A1 = triangle_area(p, b, c)
    A2 = triangle_area(a, p, c)
    A3 = triangle_area(a, b, p)

    return abs(A - (A1 + A2 + A3)) < 1e-10  # Rundungsfehlern
end

function find_triangle(p::Punkt, D::Delaunay)::Dreieck
    for t in D.triangles
        a = t.edge.origin
        b = t.edge.next.origin
        c = t.edge.prev.origin

        if _point_in_triangle(p, a, b, c)
            return t
        end
    end
end

function insert_point!(p::Punkt, D::Delaunay)
    abc = find_triamgle(p, D)

    a = abc.edge.origin
    b = abc.edge.next.origin
    c = abc.edge.prev.origin

    # Später noch Fall abdecken, wenn Punkt auf der Kante liegt

    

    
