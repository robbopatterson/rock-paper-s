module HomePage exposing (main)

import Browser
import Delay
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, string)
import Json.Decode.Pipeline exposing (required)


type alias MainModel =
    { byline : String
    , imageUrl : String
    , title : String
    , username : String
    , usernameLogo : String
    }


type alias ItemModel =
    { byline : String
    , imageUrl : String
    , title : String
    , href: String
    }


type alias NavButtonModel =
    { name : String
    , url : String
    }


type alias Model =
    { main : Maybe MainModel
    , items : List ItemModel
    , navButtons : List NavButtonModel
    }


view : Model -> Html msg
view model =
    case model.main of
        Nothing ->
            div [] [ text "Loading" ]

        Just mainProfile ->
            div []
                [ nav [ id "topNav", class "navbar navbar-expand-md navbar-light" ]
                    [ div [ class "container" ]
                        [ a [ class "navbar-brand", href "/" ]
                            [ img [ src mainProfile.usernameLogo, width 30, height 30, class "d-inline-block align-top", alt "Logo" ] []
                            , span [] [ text mainProfile.username ]
                            ]
                        , button [ class "navbar-toggler", type_ "button", attribute "data-toggle" "collapse", attribute "data-target" "#navbarNav", attribute "aria-controls" "navbarNav", attribute "aria-expanded" "false", attribute "aria-label" "Toggle navigation" ]
                            [ span [ class "navbar-toggler-icon" ] []
                            ]
                        , div [ class "collapse navbar-collapse text-center", id "navbarNav" ]
                            [ ul [ class "navbar-nav ml-auto" ]
                                (List.map
                                    (\nbi ->
                                        li [ class "nav-item" ]
                                            [ a [ class "nav-link", href nbi.url ] [ text nbi.name ]
                                            ]
                                    )
                                    model.navButtons
                                )
                            ]
                        ]
                    ]
                , div [ class "container" ]
                    [ div [ class "row justify-content-center my-3" ]
                        [ div [ class "col-5" ]
                            [ img [ src mainProfile.imageUrl, class "img-fluid" ] []
                            ]
                        ]
                    , div [ class "row justify-content-center mb-3" ]
                        [ div [ class "col-md-9 text-center" ]
                            [ h1 [ id "hometext", class "font-weight-bold" ] [ text mainProfile.title ]
                            , i [] [ text mainProfile.byline ]
                            ]
                        ]
                    , h2 [ class "mt-5" ] [ text "Portfolio" ]
                    , hr [] []
                    , div [ class "row" ]
                        (List.map
                            (\item ->
                                div [ class "col-lg-4 col-md-6" ]
                                    [ a [ href item.href ]
                                        [ img [ src item.imageUrl, class "img-fluid mb-2" ] []
                                        ]
                                    , h3 [] [ text item.title ]
                                    , p [] [ text item.byline ]
                                    ]
                            )
                            model.items
                        )
                    ]
                ]


initialModel : Model
initialModel =
    { main = Nothing
    , items = []
    , navButtons = []
    }


type Msg
    = SendHttpRequest
    | MainReceived (Result Http.Error MainModel)
    | ItemsReceived (Result Http.Error (List ItemModel))
    | NavButtonsReceived (Result Http.Error (List NavButtonModel))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendHttpRequest ->
            ( model, getMain )

        MainReceived result ->
            case result of
                Ok mainModel ->
                    ( { model | main = Just mainModel }, Cmd.none )

                Err httpError ->
                    ( model, Cmd.none )

        ItemsReceived result ->
            case result of
                Ok items ->
                    ( { model | items = items }, Cmd.none )

                Err httpError ->
                    ( model, Cmd.none )

        NavButtonsReceived result ->
            case result of
                Ok navButtons ->
                    ( { model | navButtons = navButtons }, Cmd.none )

                Err httpError ->
                    ( model, Cmd.none )


mainDecoder : Decoder MainModel
mainDecoder =
    Decode.succeed MainModel
        |> Json.Decode.Pipeline.required "byline" string
        |> Json.Decode.Pipeline.required "imageUrl" string
        |> Json.Decode.Pipeline.required "title" string
        |> Json.Decode.Pipeline.required "username" string
        |> Json.Decode.Pipeline.required "username-logo" string


itemDecoder : Decoder ItemModel
itemDecoder =
    Decode.succeed ItemModel
        |> Json.Decode.Pipeline.required "byline" string
        |> Json.Decode.Pipeline.required "imageUrl" string
        |> Json.Decode.Pipeline.required "title" string
        |> Json.Decode.Pipeline.required "href" string


navButtonDecoder : Decoder NavButtonModel
navButtonDecoder =
    Decode.succeed NavButtonModel
        |> Json.Decode.Pipeline.required "name" string
        |> Json.Decode.Pipeline.required "url" string


host =
    "https://portfolio-api.robdev.ca"


getMain : Cmd Msg
getMain =
    Http.get
        { url = host ++ "/portfolio/main"
        , expect = Http.expectJson MainReceived mainDecoder
        }


getItems : Cmd Msg
getItems =
    Http.get
        { url = host ++ "/portfolio-item"
        , expect = Http.expectJson ItemsReceived (Decode.list itemDecoder)
        }


getNavButtons : Cmd Msg
getNavButtons =
    Http.get
        { url = host ++ "/nav-button"
        , expect = Http.expectJson NavButtonsReceived (Decode.list navButtonDecoder)
        }


main : Program () Model Msg
main =
    Browser.element
        { init = \flags -> ( initialModel, Cmd.batch [ getMain, getItems, getNavButtons ] )
        , view = view
        , update = update
        , subscriptions = \model -> Sub.none
        }
