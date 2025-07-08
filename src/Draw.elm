module Draw exposing (..)

import Parse exposing (Point(..), Vector(..))
import Svg exposing (..)
import Svg.Attributes exposing (class, cx, cy, fill, height, id, markerEnd, markerHeight, markerWidth, orient, r, refX, refY, stroke, strokeWidth, viewBox, width, x1, x2, y1, y2)



-- Centro del SVG


centerX : Float -> Float
centerX svgWidth =
    svgWidth / 2


centerY : Float -> Float
centerY svgHeight =
    svgHeight / 2


axis : Float -> Float -> Svg a
axis svgHeight svgWidth =
    g [ class "axes" ]
        [ -- Eje X (horizontal)
          line [ x1 "0", y1 (String.fromFloat (centerY svgHeight)), x2 (String.fromFloat svgWidth), y2 (String.fromFloat (centerY svgHeight)), class "x-axis" ] []
        , -- Eje Y (vertical)
          line [ x1 (String.fromFloat (centerX svgWidth)), y1 "0", x2 (String.fromFloat (centerX svgWidth)), y2 (String.fromFloat svgHeight), class "y-axis" ] []
        ]


arrowMarker : Svg a
arrowMarker =
    defs []
        [ marker
            [ id "arrowhead"
            , markerWidth "10"
            , markerHeight "7"
            , refX "9"
            , refY "3.5"
            , orient "auto"
            ]
            [ polygon
                [ Svg.Attributes.points "0 0, 10 3.5, 0 7"
                , fill "blue"
                , stroke "blue"
                , strokeWidth "0"
                ]
                []
            ]
        ]



-- Convierte coordenadas del sistema matemático al sistema SVG
-- En el sistema matemático: (0,0) está en el centro, Y crece hacia arriba
-- En el sistema SVG: (0,0) está en la esquina superior izquierda, Y crece hacia abajo


transformCoordinates : Float -> Float -> Float -> Float -> ( Float, Float )
transformCoordinates x y svgHeight svgWidth =
    ( centerX svgWidth + x
      -- X: desplazar por el centro
    , centerY svgHeight - y
      -- Y: invertir y desplazar por el centro
    )


pointToSvg : Float -> Float -> Point -> Svg a
pointToSvg svgHeight svgWidth (Point point) =
    let
        ( svgX, svgY ) =
            transformCoordinates point.x point.y svgHeight svgWidth
    in
    circle
        [ r "4"
        , cx (String.fromFloat svgX)
        , cy (String.fromFloat svgY)
        , stroke "red"
        , strokeWidth "2"
        , fill "red"
        ]
        []


vectorToSvg : Float -> Float -> Vector -> Svg a
vectorToSvg svgHeight svgWidth (Vector vector) =
    let
        ( svgX, svgY ) =
            transformCoordinates vector.x vector.y svgHeight svgWidth
    in
    line
        [ x1 (String.fromFloat (centerX svgWidth))
        , y1 (String.fromFloat (centerY svgHeight))
        , x2 (String.fromFloat svgX)
        , y2 (String.fromFloat svgY)
        , stroke "blue"
        , strokeWidth "2"
        , markerEnd "url(#arrowhead)"
        ]
        []


mainSvg : Float -> Float -> List Point -> List Vector -> Svg a
mainSvg svgHeight svgWidth points vectors =
    svg
        [ width (String.fromFloat svgWidth)
        , height (String.fromFloat svgHeight)
        , viewBox ("0 0 " ++ String.fromFloat svgWidth ++ " " ++ String.fromFloat svgHeight)
        ]
        [ arrowMarker
        , axis svgHeight svgWidth
        , g [ class "points" ]
            (List.map (pointToSvg svgHeight svgWidth) points)
        , g [ class "vectors" ]
            (List.map (vectorToSvg svgHeight svgWidth) vectors)
        ]
