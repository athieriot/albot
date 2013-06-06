Configuration = require './configuration'
_ = require('underscore')._

Github = Configuration.Github
Async = require 'async'
Moment = require 'moment'

Utils = require './utils'

isRepoInFilters = (name) ->
  repo_filters = Configuration.Github.Filters
  _.some repo_filters, (filter) ->
    name.indexOf(filter) > -1

checkRecentDate = (createdAt, filter) ->
  period = if _.isString(filter) then filter else 'weeks'
  #TODO: Check the different filter possibilities (weeks, days...)
  thisUnit = Moment().subtract(period, 1)
  Moment(createdAt).isAfter(thisUnit)

shouldBeDisplayed = (keyword, filter, title, createdAt) ->
  if (keyword is 'last' and _.isString(filter) and _.isNaN(parseInt(filter)))
    keyword = 'with'

  if (keyword is 'recent' and createdAt?)
    checkRecentDate(createdAt, filter)
  else if (not _.isString(filter)) then true
  else
    term = filter.toLowerCase()
    query = title.toLowerCase()
    if (keyword is 'without' and query.indexOf(term) > -1) then false
    else if (keyword is 'with' and query.indexOf(term) == -1) then false
    else true

pickLastIfNeeded = (keyword, filter, list) ->
  if (keyword is 'last')
    number = if (_.isString(filter) and not _.isNaN(parseInt(filter)))
      parseInt(filter)
    else 1

    _.first(list, number)
  else list

buildStatus = (statuses) ->
  status = statuses[0] if statuses?
  if not status? or not status.state? or status.state is 'pending'
    undefined
  else status.state is 'success'

needAttention = (mergeable, state) ->
  warning = ""
  warning = if not mergeable then " - *NEED REBASE*" else warning
  warning = if state is 'closed' then " - *CLOSED*" else warning
  warning

getInfoPull = (org, reponame, number, callback) ->
  Github.Api.pullRequests.get {
    user: org,
    repo: reponame,
    number: number
  }, (error, details) =>
    Github.Api.statuses.get {
      user: org,
      repo: reponame,
      sha: details.head.sha
    }, (error, statuses) ->
      callback error, {
        title: details.title,
        url: details.html_url,
        infos: reponame,
        comments: "(#{details.head.ref} -> #{details.base.ref}) - " +
                  Moment(details.created_at).fromNow() + " - " +
                  details.comments + " comments" +
                  needAttention(details.mergeable, details.state),
        status: buildStatus(statuses),
        avatar: details.user.gravatar_id,
        order: details.created_at
      }

#TODO: Speeeeeeeeeeed
pulls = (fallback, keyword, filter) ->

  githubUrlPattern = new RegExp "(http|https):\/\/github.com+
([a-z0-9\-\.,@\?^=%&;:\/~\+#]*[a-z0-9\-@\?^=%&;\/~\+#])?"
  , 'i'

  # First we verify if the argument is an URL
  matching = keyword.match(githubUrlPattern) if _.isString(keyword)
  if (matching and keyword.indexOf('pull') > -1)
    pull = matching[2].split('\/')
    getInfoPull pull[1], pull[2], pull[4], (error, result) ->
      if (not error)
        Utils.fallback_print(fallback) {
          title: result.title,
          url: result.url,
          infos: result.infos,
          comments: result.comments,
          status: result.status,
          avatar: result.avatar
        }
  else
    Github.Api.repos.getFromOrg {
      org: Github.Org,
      per_page: 100
    }, (error, repos) ->
      Async.concat repos, (repo, callback) ->
        if (isRepoInFilters(repo.name))
          Github.Api.pullRequests.getAll {
            user: Github.Org,
            repo: repo.name
          }, (error, prs) ->
            if (error)
              callback(error)
            else
              Async.reduce prs, [],
                Async.apply (memo, pr, cb) ->
                  query = pr.title + repo.name + pr.user.login
                  if (shouldBeDisplayed(keyword, filter, query, pr.created_at))
                    getInfoPull Github.Org, repo.name, pr.number, (error, r) ->
                      memo.push r
                      cb null, memo
                  else
                    cb(error, memo)
              , (err, list) ->
                callback(err, list)
        else
          callback(null, [])
      , (err, list) ->
        if (err)
          console.log "An error occured"
        else
          Utils.fallback_printList fallback,
            list, _.partial(pickLastIfNeeded, keyword, filter)

module.exports = {
  name: "Pull Requests"
  description: " [ -url- |
 without -filter- | with -filter- |
 recent [-unit-] |
 last [-number- | -filter-]
 ] List all Pull Requests of the organisation",
  action: pulls,
  isRepoInFilters: isRepoInFilters,
  shouldBeDisplayed: shouldBeDisplayed,
  pickLastIfNeeded: pickLastIfNeeded
}
