module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events
import Draw exposing (ZeroSvg, mainSvg)
import Html exposing (Html, a, button, div, img, input, p, text)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, onSubmit)
import Json.Decode as Decode
import List exposing (filter, member)
import Parse exposing (Point(..), Vector(..), deadEndsToString, point, pointToString, vector, vectorToString)
import Parser exposing (Parser, oneOf, run)
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { points : List Point
    , vectors : List Vector
    , inputText : String
    , parseError : String
    , svg : ZeroSvg
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { points = [ Point { name = "A", x = 5, y = 10 } ]
      , vectors = [ Vector { name = "u", x = -3, y = 5 } ]
      , inputText = ""
      , parseError = ""
      , svg =
            { size = { width = 800.0, height = 600.0 }
            , center = { x = 0.0, y = 0.0 }
            , scale = 20.0
            }
      }
    , getSvgSizeCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onResize (\_ _ -> GetSvgSize)



-- UPDATE


onWheel : (Float -> msg) -> Html.Attribute msg
onWheel tagger =
    on "wheel" (Decode.map tagger (Decode.at [ "deltaY" ] Decode.float))


type Msg
    = Add
    | DeletePoint Point
    | DeleteVector Vector
    | UpdateInput String
    | GetSvgSize
    | GotSvgSize (Result Dom.Error Dom.Element)
    | WheelMoved Float


getSvgSizeCmd : Cmd Msg
getSvgSizeCmd =
    Task.attempt GotSvgSize (Dom.getElement "svg")


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateInput text ->
            ( { model | inputText = text }, Cmd.none )

        Add ->
            if model.inputText /= "" then
                case run (parserMaster model) model.inputText of
                    Ok newModel ->
                        ( newModel, Cmd.none )

                    Err err ->
                        ( { model | parseError = deadEndsToString err }, Cmd.none )

            else
                ( model, Cmd.none )

        DeletePoint pointToDelete ->
            ( { model | points = filter (areDifferentPoint pointToDelete) model.points }, Cmd.none )

        DeleteVector vectorToDelete ->
            ( { model | vectors = filter (areDifferentVector vectorToDelete) model.vectors }, Cmd.none )

        GetSvgSize ->
            ( model, getSvgSizeCmd )

        GotSvgSize (Ok element) ->
            let
                svg =
                    model.svg

                updatedSvg =
                    { svg | size = { width = element.element.width, height = element.element.height } }
            in
            ( { model | svg = updatedSvg }
            , Cmd.none
            )

        GotSvgSize (Err _) ->
            ( model, getSvgSizeCmd )

        WheelMoved moved ->
            let
                svg =
                    model.svg

                newScale =
                    svg.scale * (1 - moved / 1000)

                updatedSvg =
                    { svg | scale = clamp 1 1000 newScale }
            in
            ( { model | svg = updatedSvg }
            , Cmd.none
            )


parserMaster : Model -> Parser Model
parserMaster model =
    oneOf
        [ Parser.map
            (\p ->
                if member p model.points then
                    { model | parseError = "Duplicate Point" }

                else
                    { model | points = p :: model.points, inputText = "" }
            )
            point
        , Parser.map
            (\v ->
                if member v model.vectors then
                    { model | parseError = "Duplicate Vector" }

                else
                    { model | vectors = v :: model.vectors, inputText = "" }
            )
            vector
        ]


areDifferentPoint : Point -> Point -> Bool
areDifferentPoint (Point p1) (Point p2) =
    p1.name /= p2.name


areDifferentVector : Vector -> Vector -> Bool
areDifferentVector (Vector v1) (Vector v2) =
    v1.name /= v2.name



-- VIEW


pointToDiv : Point -> Html Msg
pointToDiv point =
    div [ class "entry" ]
        [ div [ class "entry-text" ] [ text (pointToString point) ]
        , button [ class "minus-button", onClick (DeletePoint point) ] [ text "-" ]
        ]


vectorToDiv : Vector -> Html Msg
vectorToDiv vector =
    div [ class "entry" ]
        [ div [ class "entry-text" ] [ text (vectorToString vector) ]
        , button [ class "minus-button", onClick (DeleteVector vector) ] [ text "-" ]
        ]


errorToDiv : String -> Html Msg
errorToDiv error =
    div [ class "error" ] [ text error ]


socialsDiv : Html Msg
socialsDiv =
    a [ class "socials", target "_black", href "https://github.com/tedius-git/zero" ] [ img [ src "./src/assets/github-mark.svg", style "height" "30px" ] [] ]


viewInput : String -> Html Msg
viewInput inputText =
    Html.form [ class "add", onSubmit Add ] [ input [ class "add-input", value inputText, onInput UpdateInput ] [], button [ class "plus-button", onClick Add ] [ text "+" ] ]


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "input" ]
            [ viewInput model.inputText
            , div [] [ errorToDiv model.parseError ]
            , div [] (List.reverse (List.map pointToDiv model.points))
            , div [] (List.reverse (List.map vectorToDiv model.vectors))
            , div [ class "spacer" ] []
            , socialsDiv
            ]
        , div [ id "svg", onWheel WheelMoved ]
            [ mainSvg model.svg model.points model.vectors
            ]
        ]
