# frozen_string_literal: true

module Healer
  class Cutover
    def initialize(options = {}); end

    def banzai!
      extract
      move_objects
      cleanup
    end

    private

    def extract
      # pull data from old Heroku install into a dumpfile
      # load dumpfile into temporary DB
    end

    def move_objects
      # reverse dependency tree for current design
      # transform each object
      # load each object
    end

    def transform
      # convert source from temp DB into JSON for new DB
    end

    def load
      # insert via AR
    end

    def cleanup
      # Drop temporary DB
    end
  end
end
