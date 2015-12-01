{CompositeDisposable} = require 'atom'
GpoolDiffView         = require './gpool-diff-view'
helper                = require './helpers'
GpoolListView         = null


# The list view object
gpoolListView = null

# Called to toggle the list view object's state
toggleGpoolList = ->
  GpoolListView ?= require './gpool-list-view'  # Require the class, if we haven't already
  gpoolListView ?= new GpoolListView()          # Create an instance, if we haven't already
  gpoolListView.toggle()                         # Toggle the view



module.exports =
  
  # The config settings
  config:
    copySettingsFromGitDiff:
      type: 'boolean'
      default: true
    showIconsInEditorGutter:
      type: 'boolean'
      default: false
  
  
  # The {CompositeDisposable} used to store subscriptions
  subscriptions: null
  
  # Whether or not this plugin is activated
  active: false
  
  # The assoc array of the toggle commands
  toggleCommands: {}
  
  
  # Called when atom activates this package - intentionally left blank
  activate: ->
  
  # Comsumes the gpool object
  consumeGpoolServiceV1: (@gpl) ->
    helper.setInstance @gpl                 # Put the instance into the helpers - needed to get the proper repository
    @gpl.registerPlugin "gpool-diff", this  # Register this plugin
  
  
  # Called when atom deactivates this package
  deactivate: ->
    @gpl?.unregisterPlugin "gpool-diff"  # Unregister this plugin, if the gpl object exists
    gpoolListView?.cancel()                     # Remove the view from the screen
    gpoolListView = null                        # Delete the instance
  
  
  observe: ->
    atom.workspace.observeTextEditors (editor) =>
      new GpoolDiffView(editor)  # Create a DiffView for this editor
      
      @toggleCommands[editor.getPath()] ?= atom.commands.add(atom.views.getView(editor), 'gpool-diff:toggle-diff-list', toggleGpoolList)  # Add the toggle command, if it doesn't already exist
  
  
  # Called to check if this plugin is active
  gpl_isActive: -> @active
  
  
  # Called when the 'gpool' package activates this plugin
  gpl_activatePlugin: ->
    return if @active  # If the plugin is already activated, there's no point in continuing
    
    @active = true                                            # State that this plugin is now active
    @subscriptions = new CompositeDisposable                  # Create the subscriptions collection
    @subscriptions.add @gpl.onRepoListChange => @observe()  # Re-build the observers when the repository list changes
    @observe()                                                # Observe the editor now
  
  
  # Called when the 'gpool' package deactivates this plugin
  gpl_deactivatePlugin: ->
    return unless @active  # If the plugin is already deactivated, there's no point in continuing
    
    @active = false              # State that this plugin is no longer active
    @subscriptions.dispose()     # Dispose of the subscriptions
    @subscriptions = null        # Remove the subscriptions object
    for _, c of @toggleCommands  # For each toggle command...
      c.dispose()                #   Dispose of the object
    @toggleCommands = {}         # Remove the list of toggle commands