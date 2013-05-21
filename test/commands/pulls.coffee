should = require('chai').should()

Commands = require '../../lib/commands'
Nock = require 'nock'

describe 'Commands', () ->
  describe '#pulls()', () ->
    before () ->
      Nock('https://api.github.com')
        .get('/orgs/testorg/repos?per_page=100&access_token=testtoken')
        .reply(200, [
            {
              "name": "test-repo",
            }
          ])
        .get('/repos/testorg/test-repo/pulls?access_token=testtoken')
        .reply(200, [
            {
              "number": 1,
            }
          ])
        .get('/repos/testorg/test-repo/pulls/1?access_token=testtoken')
        .reply(200, {
              "html_url": "https://github.com/octocat/Hello-World/pulls/1",
              "title": "new-feature",
              "mergeable": false,
              "comments": 10,
              "user": {
              },
              "head": {
                "sha": "testsha"
              }
            }
          )
        .get('/repos/testorg/test-repo/statuses/testsha?access_token=testtoken')
        .reply(200, [
            {
              "state": "success"
            }
          ])

    it 'should list Pull Requests', (done) ->
      Commands.pulls.action (title, url, infos, comments, status) ->
        title.should.equal "new-feature"
        url.should.equal "https://github.com/octocat/Hello-World/pulls/1"
        infos.should.equal "test-repo"
        comments.should.equal "10 comments - *NEED REBASE*"
        status.should.equal true
        done()

  describe '#pulls()#isRepoInFilters()', () ->
    it 'should not accept unfilterd name', () ->
      test = Commands.pulls.isRepoInFilters("notinthelist")
      test.should.be.false

    it 'should accept any filter name', () ->
      test = Commands.pulls.isRepoInFilters("test-repo")
      test.should.be.true

      test = Commands.pulls.isRepoInFilters("another-one")
      test.should.be.true

  describe '#pulls()#shouldBeDisplayed()', () ->
    it 'should display normal request', () ->
      test = Commands.pulls.shouldBeDisplayed()
      test.should.be.true

    it 'should hide requested term', () ->
      test = Commands.pulls.shouldBeDisplayed('without', 'stuff', 'Line with stuff in it')
      test.should.be.false

    it 'should display anything else', () ->
      test = Commands.pulls.shouldBeDisplayed('without', 'stuff', 'Line with things in it')
      test.should.be.true

      test = Commands.pulls.shouldBeDisplayed('truc', 'stuff', 'Line with things in it')
      test.should.be.true

      test = Commands.pulls.shouldBeDisplayed('machin')
      test.should.be.true
