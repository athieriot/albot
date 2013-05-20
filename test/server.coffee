Nconf = require 'nconf'
Nconf.env().file({file: '../.albot.json'})

should = require('chai').should()

Server = require '../lib/server'

describe 'Server', () ->
  describe '#dispach()', () ->
    it 'should find the right command based on a message line', () ->
      cmd = Server.dispatch("#{Nconf.get("nickname")} pulls")
      cmd.should.have.property('name').equal("Pull Requests")

    it 'should not dispatch for anything', () ->
      cmd = Server.dispatch("anything")
      should.not.exist cmd

    it 'should match argument', () ->
      cmd = Server.dispatch("#{Nconf.get("nickname")} tag repository")
      cmd.should.have.property('name').equal("Tag")
      cmd.should.have.property('arg').equal("repository")
