module = angular.module "prat", ["ngRoute"]

module.config ($routeProvider) ->
  $routeProvider.when "/",
    templateUrl: "main-template"
    controller: "mainCtrl"
    controllerAs: "main"

module.controller "mainCtrl", ->
  console.log "main"
