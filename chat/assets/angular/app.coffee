dependencies = [
  "ngCookies"
  "ngRoute"
  "ngSanitize"
  "ui.bootstrap"
  "ui.keypress"
  "ui.router"
  "ui.sortable"
  "prat.services"
  "pasvaz.bindonce"
]

module = angular.module "prat", dependencies

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
