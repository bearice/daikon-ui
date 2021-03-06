module = angular.module 'daikon'

module.directive 'waitForLoading', ->
  restrict: 'AE',
  transclude: true,
  scope:
    loading:'='
  template: """
    <div ng-if="loading" ng-transclude />
    <div ng-if="!loading">
      <h1 class="text-center">
        <span class="glyphicon glyphicon-time></span>Loading ...
      </h1>
    </div>
  """
  link: (scope, element, attrs, ctrl, transclude) ->
    transclude scope.$parent, (clone, scope)->
      element.append(clone)

module.directive 'selectServer', ->
  restrict: 'E',
  require: 'ngModel',
  scope:
    list: '=data'
    model: '=ngModel'
  template: '''
    <div  isteven-multi-select
          input-model="list"
          output-model="selected"
          tick-property="selected"
          button-label="Name"
          item-label="Name"
          search-property="Name"
          output-properties="Name"
          on-close="sync()" />
    '''

  controller: ($scope)->
    $scope.model = [] if $scope.model is undefined
    $scope.selected = []
    $scope.sync = ->
      s = (x.Name for x in $scope.selected)
      $scope.model.splice 0,$scope.model.length,s...

  link: (scope,elem,attr,ctrl)->
    scope.$watchGroup ['list','model'], ->
      scope.list.forEach (x)->
        x.selected = scope.model.indexOf(x.Name)>=0

module.directive 'appEditor', ->
  restrict: 'E',
  require: 'ngModel',
  scope:
    data:'=ngModel'
    updateMode: '='

  templateUrl: 'public/templates/app-editor.html'
  controller: ($scope,$q,Service,Template,Etcd)->
    $scope.isLoading = true
    $scope.envs = []
    $scope.apps = []
    $scope.templates = {}
    $scope.servers = []

    promises = []
    promises.push Service.listEnv().$promise.then (data)->
      envs = {}
      apps = {}
      for x in data
        envs[x._id] = true
        apps[a] = true for a in x.apps
      $scope.envs = _.keys(envs).sort()
      $scope.apps = _.keys(apps).sort()

    promises.push Template.query().$promise.then (data)->
      $scope.templates[a.name] = a for a in data

    promises.push Etcd.loadServers().then (data)->
      $scope.servers = _.sortBy data, 'Name'

    $q.all(promises).then ->
      $scope.isLoading = false

  link: ($scope, $element, $attrs, ngModel)->
    $scope.$watch 'data', ->
      $scope.hosts = $scope.data.options.hosts
      $scope.overrideImage = $scope.data.image isnt undefined

    $scope.$watch 'hosts', ->
      $scope.data.options.hosts = $scope.hosts

    $scope.$watch 'overrideImage', ->
      if $scope.overrideImage
        $scope.data.image = $scope.customImage
      else
        delete $scope.data.image
        $scope.customImage = "docker.jimubox.com/#{$scope.data.env}/#{$scope.data.app}:latest"

    $scope.$watch 'customImage', ->
      if $scope.overrideImage
        $scope.data.image = $scope.customImage

    $scope.$watchGroup ['data.env','data.app'], ()->
      $scope.customImage = "docker.jimubox.com/#{$scope.data.env}/#{$scope.data.app}:latest" unless $scope.overrideImage

module.directive 'volumeList', ->
  restrict: 'E',
  require: 'ngModel',
  scope:
    data:'=ngModel'
  templateUrl: 'public/templates/volume-list.html'
  link: (scope, element, attrs, ctrl)->
    scope.$watch 'data', (n,o)->
      console.info 'data changed:', n, o
  controller: ($scope)->
    $scope.addItem = ->
      $scope.data = [] if $scope.data is undefined
      $scope.data.push {}

    $scope.delItem = (index)->
      $scope.data.splice index,1

