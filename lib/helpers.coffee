module.exports =
  # Sets the @gpl instance
  setInstance: (@gpl) ->
  
  # Returns the repository for the given path
  repositoryForPath: (path) -> @gpl?.host?.getRepoForPath?(path)