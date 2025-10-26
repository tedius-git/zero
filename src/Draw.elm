module Draw exposing (..)

import List exposing (repeat)
import Parse exposing (Point(..), Vector(..))
import Svg exposing (..)
import Svg.Attributes exposing (class, cx, cy, fill, height, id, markerEnd, markerHeight, markerWidth, orient, r, refX, refY, stroke, strokeWidth, viewBox, width, x1, x2, y1, y2)


type alias ZeroSvg =
    { size : { width : Float, height : Float }
    , center : { x : Float, y : Float }
    , scale : Float
    }



-- Centro del SVG


centerX : ZeroSvg -> Float
centerX svg =
    svg.size.width / 2 + svg.center.x


centerY : ZeroSvg -> Float
centerY svg =
    svg.size.height / 2 + svg.center.y



-- Convierte coordenadas del sistema matemático al sistema SVG
-- En el sistema matemático: (0,0) está en el centro, Y crece hacia arriba
-- En el sistema SVG: (0,0) está en la esquina superior izquierda, Y crece hacia abajo


transformX : ZeroSvg -> Float -> Float
transformX svg x =
    centerX svg + x * svg.scale


transformY : ZeroSvg -> Float -> Float
transformY svg y =
    centerY svg - (y * svg.scale)


transformCoordinates : ZeroSvg -> Float -> Float -> ( Float, Float )
transformCoordinates svg x y =
    ( transformX svg x
    , transformY svg y
    )


axis : ZeroSvg -> Svg a
axis svg =
    g [ class "axis" ]
        [ -- Eje X
          line [ x1 "0", y1 (String.fromFloat (centerY svg)), x2 (String.fromFloat svg.size.width), y2 (String.fromFloat (centerY svg)), class "x-axis" ] []
        , -- Eje Y
          line [ x1 (String.fromFloat (centerX svg)), y1 "0", x2 (String.fromFloat (centerX svg)), y2 (String.fromFloat svg.size.height), class "y-axis" ] []
        ]


grid : ZeroSvg -> Float -> List (Svg a)
grid svg gridScale =
    let
        toSvgX : Float -> String
        toSvgX x =
            String.fromFloat (transformX svg x)

        toSvgY : Float -> String
        toSvgY y =
            String.fromFloat (transformY svg y)
    in
    List.indexedMap (\i -> \_ -> line [ x1 (String.fromFloat 0), y1 (toSvgY (toFloat i * gridScale)), x2 (String.fromFloat svg.size.width), y2 (toSvgY (toFloat i * gridScale)) ] []) (repeat (round (svg.size.height / 2)) 0)
        ++ List.indexedMap (\i -> \_ -> line [ x1 (String.fromFloat 0), y1 (toSvgY (toFloat i * -gridScale)), x2 (String.fromFloat svg.size.width), y2 (toSvgY (toFloat i * -gridScale)) ] []) (repeat (round (svg.size.height / 2)) 0)
        ++ List.indexedMap (\i -> \_ -> line [ y1 (String.fromFloat 0), x1 (toSvgX (toFloat i * gridScale)), y2 (String.fromFloat svg.size.height), x2 (toSvgX (toFloat i * gridScale)) ] []) (repeat (round (svg.size.width / 2)) 0)
        ++ List.indexedMap (\i -> \_ -> line [ y1 (String.fromFloat 0), x1 (toSvgX (toFloat i * -gridScale)), y2 (String.fromFloat svg.size.height), x2 (toSvgX (toFloat i * -gridScale)) ] []) (repeat (round (svg.size.width / 2)) 0)


mainGrid : ZeroSvg -> Svg a
mainGrid svg =
    g [ class "main-grid" ]
        (grid svg 5)


secundGrid : ZeroSvg -> Svg a
secundGrid svg =
    g [ class "secund-grid" ]
        (grid svg 1)


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


pointToSvg : ZeroSvg -> Point -> Svg a
pointToSvg svg (Point point) =
    let
        ( svgX, svgY ) =
            transformCoordinates svg point.x point.y
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


vectorToSvg : ZeroSvg -> Vector -> Svg a
vectorToSvg svg (Vector vector) =
    let
        ( svgX, svgY ) =
            transformCoordinates svg vector.x vector.y
    in
    line
        [ x1 (String.fromFloat (centerX svg))
        , y1 (String.fromFloat (centerY svg))
        , x2 (String.fromFloat svgX)
        , y2 (String.fromFloat svgY)
        , stroke "blue"
        , strokeWidth "2"
        , markerEnd "url(#arrowhead)"
        ]
        []


mainSvg : ZeroSvg -> List Point -> List Vector -> Svg a
mainSvg zeroSvg points vectors =
    svg
        [ id "graph"
        , width (String.fromFloat zeroSvg.size.width)
        , height (String.fromFloat zeroSvg.size.height)
        , viewBox ("0 0 " ++ String.fromFloat zeroSvg.size.width ++ " " ++ String.fromFloat zeroSvg.size.height)
        ]
        [ arrowMarker
        , secundGrid zeroSvg
        , mainGrid zeroSvg
        , axis zeroSvg
        , g [ class "points" ]
            (List.map (pointToSvg zeroSvg) points)
        , g [ class "vectors" ]
            (List.map (vectorToSvg zeroSvg) vectors)
        ]
