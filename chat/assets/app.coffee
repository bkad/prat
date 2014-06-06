module = angular.module "prat", [
  "ngCookies"
  "ngRoute"
  "ngSanitize"
  "ui.bootstrap"
  "ui.keypress"
  "ui.sortable"
  "prat.services"
]

module.constant("config", INITIAL)

module.config ($routeProvider, $tooltipProvider) ->
  $routeProvider.when "/",
    templateUrl: "main-template"
    controller: "main"
    controllerAs: "main"

  $tooltipProvider.options
    placement: "top"
    animation: true
    popupDelay: 0
    appendToBody: true
