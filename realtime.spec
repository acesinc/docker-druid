[{
    "schema": {
        "dataSource": "webstream",
        "aggregators": [
            {"type": "count", "name": "rows"},
            {"type": "doubleSum", "fieldName": "known_users", "name": "known_users"}
        ],
        "indexGranularity": "second",
        "shardSpec": {"type": "none"}
      },

    "config": {
        "maxRowsInMemory": 50000,
        "intermediatePersistPeriod": "PT2m"
    },

    "firehose": {
        "type": "webstream",
        "url":"http://developer.usa.gov/1usagov",
    "renamedDimensions": {
      "g":"bitly_hash",
      "c":"country",
      "a":"user",
      "cy":"city",
      "l":"encoding_user_login",
      "hh":"short_url",
      "hc":"timestamp_hash",
      "h":"user_bitly_hash",
      "u":"url",
      "tz":"timezone",
      "t":"time",
      "r":"referring_url",
      "gr":"geo_region",
      "nk":"known_users",
      "al":"accept_language"
      },
    "timeDimension":"t",
    "timeFormat":"posix"
    },

    "plumber": {
        "type": "realtime",
        "windowPeriod": "PT3m",
        "segmentGranularity": "hour",
        "basePersistDirectory": "/tmp/example/usagov_realtime/basePersist"
    }
},
{
    "schema": {
        "dataSource": "wikipedia",
        "aggregators": [
            {"type": "count", "name": "count"},
            {"type": "longSum", "fieldName": "added", "name": "added"},
            {"type": "longSum", "fieldName": "deleted", "name": "deleted"},
            {"type": "longSum", "fieldName": "delta", "name": "delta"}
        ],
        "indexGranularity": "minute",
        "shardSpec": {"type": "none"}
      },

    "config": {
        "maxRowsInMemory": 50000,
        "intermediatePersistPeriod": "PT2m"
    },

    "firehose": {
        "type": "irc",
        "nick": "wiki1234567890",
        "host": "irc.wikimedia.org",
        "channels": [
          "#en.wikipedia",
          "#fr.wikipedia",
          "#de.wikipedia",
          "#ja.wikipedia"
        ],
        "decoder":  {
          "type": "wikipedia",
          "namespaces": {
            "#en.wikipedia": {
              "": "main",
              "Category": "category",
              "$1 talk": "project talk",
              "Template talk": "template talk",
              "Help talk": "help talk",
              "Media": "media",
              "MediaWiki talk": "mediawiki talk",
              "File talk": "file talk",
              "MediaWiki": "mediawiki",
              "User": "user",
              "File": "file",
              "User talk": "user talk",
              "Template": "template",
              "Help": "help",
              "Special": "special",
              "Talk": "talk",
              "Category talk": "category talk"
            }
          }
        },
        "timeDimension":"timestamp",
  "timeFormat":"iso"
    },

    "plumber": {
        "type": "realtime",
        "windowPeriod": "PT3m",
        "segmentGranularity": "hour",
        "basePersistDirectory": "/tmp/example/wikipedia/basePersist"
    }
}]
