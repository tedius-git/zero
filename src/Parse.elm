module Parse exposing (..)

import Parser exposing (..)
import Set
import String exposing (fromFloat)



-- Points && Vectors -----------------------------------------------------------------------------------------


type alias NamedCoord =
    { name : String
    , x : Float
    , y : Float
    }


type Point
    = Point NamedCoord


type Vector
    = Vector NamedCoord

signFloat : Parser Float
signFloat =
    oneOf
        [ succeed negate
            |. symbol "-"
            |= float
        , float
        ]


parseCoords : Parser ( Float, Float )
parseCoords =
    succeed Tuple.pair
        |= signFloat
        |. spaces
        |. symbol ","
        |. spaces
        |= signFloat


named2DParser :
    Parser String
    -> String
    -> String
    -> (NamedCoord -> a)
    -> Parser a
named2DParser nameParser leftDelim rightDelim wrap =
    succeed (\name ( x, y ) -> wrap { name = name, x = x, y = y })
        |= nameParser
        |. spaces
        |. symbol "="
        |. spaces
        |. symbol leftDelim
        |. spaces
        |= parseCoords
        |. spaces
        |. symbol rightDelim


pointName : Parser String
pointName =
    variable { start = Char.isUpper, inner = Char.isDigit, reserved = Set.empty }


vectorName : Parser String
vectorName =
    variable { start = Char.isLower, inner = Char.isDigit, reserved = Set.empty }


point : Parser Point
point =
    named2DParser pointName "(" ")" Point


vector : Parser Vector
vector =
    named2DParser vectorName "<" ">" Vector


parsePoint : String -> Result (List DeadEnd) Point
parsePoint input =
    run point input


parseVector : String -> Result (List DeadEnd) Vector
parseVector input =
    run vector input


pointToString : Point -> String
pointToString (Point p) =
    p.name ++ ": " ++ "(" ++ fromFloat p.x ++ "," ++ fromFloat p.y ++ ")"


vectorToString : Vector -> String
vectorToString (Vector v) =
    v.name ++ ": " ++ "<" ++ fromFloat v.x ++ "," ++ fromFloat v.y ++ ">"



-- Parser All
-- Parse erros https://github.com/elm/parser/pull/16/files


deadEndsToString : List DeadEnd -> String
deadEndsToString deadEnds =
    String.concat (List.intersperse "; " (List.map deadEndToString deadEnds))


deadEndToString : DeadEnd -> String
deadEndToString deadend =
    problemToString deadend.problem ++ " at row " ++ String.fromInt deadend.row ++ ", col " ++ String.fromInt deadend.col


problemToString : Problem -> String
problemToString p =
    case p of
        Expecting s ->
            "expecting '" ++ s ++ "'"

        ExpectingInt ->
            "expecting int"

        ExpectingHex ->
            "expecting hex"

        ExpectingOctal ->
            "expecting octal"

        ExpectingBinary ->
            "expecting binary"

        ExpectingFloat ->
            "expecting float"

        ExpectingNumber ->
            "expecting number"

        ExpectingVariable ->
            "expecting variable"

        ExpectingSymbol s ->
            "expecting symbol '" ++ s ++ "'"

        ExpectingKeyword s ->
            "expecting keyword '" ++ s ++ "'"

        ExpectingEnd ->
            "expecting end"

        UnexpectedChar ->
            "unexpected char"

        Problem s ->
            "problem " ++ s

        BadRepeat ->
            "bad repeat"
