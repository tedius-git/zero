module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Draw exposing (mainSvg)
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import List exposing (filter, member)
import Parse exposing (Point(..), Vector(..), deadEndsToString, point, pointToString, vector, vectorToString)
import Parser exposing (Parser, oneOf, run)
import Task
import Html exposing (p)



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
    , svgSize : Maybe { width : Float, height : Float }
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { points = [ Point { name = "A", x = 50, y = 100 } ]
      , vectors = [ Vector { name = "u", x = -30, y = 50 } ]
      , inputText = ""
      , parseError = ""
      , svgSize = Nothing
      }
    , Task.perform (\_ -> GetSvgSize) (Task.succeed ())
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UPDATE


type Msg
    = Add
    | DeletePoint Point
    | DeleteVector Vector
    | UpdateInput String
    | GetSvgSize
    | GotSvgSize (Result Dom.Error Dom.Element)


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
            ( model
            , Task.attempt GotSvgSize (Dom.getElement "graph")
            )

        GotSvgSize (Ok element) ->
            ( { model | svgSize = Just { width = element.element.width, height = element.element.height } }
            , Cmd.none
            )

        GotSvgSize (Err _) ->
            ( model, Cmd.none )


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
        , button [ class "entry-button", onClick (DeletePoint point) ] [ text "-" ]
        ]


vectorToDiv : Vector -> Html Msg
vectorToDiv vector =
    div [ class "entry" ]
        [ div [ class "entry-text" ] [ text (vectorToString vector) ]
        , button [ class "entry-button", onClick (DeleteVector vector) ] [ text "-" ]
        ]


errorToDiv : String -> Html Msg
errorToDiv error =
    div [ class "error" ] [ text error ]


viewInput : String -> Html Msg
viewInput inputText =
    Html.form [ class "add", onSubmit Add ] [ input [ class "add-input", value inputText, onInput UpdateInput ] [], button [ class "add-button", onClick Add ] [ text "+" ] ]


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ div [ class "input" ]
            [ viewInput model.inputText
            , div [] [ errorToDiv model.parseError ]
            , div [] (List.reverse (List.map pointToDiv model.points))
            , div [] (List.reverse (List.map vectorToDiv model.vectors))
            ]
        , div [id "graph"] [
            case model.svgSize of
                Just size ->
                    mainSvg size.height size.width model.points model.vectors 
                Nothing ->
                    p [] [text "Error trying to get svg size"]
            ]
        ]
