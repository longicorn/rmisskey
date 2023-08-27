# rmisskey
CUI misskey client for myself

## Usage
```
$ export MISSKEY_URL=<url>
$ export MISSKEY_USERNAME=<username>
$ export MISSKEY_TOKEN=<token>
$ misskey.rb --help
```

## Command
### HomeTimeLine
```
$ misskey.rb -t
$ misskey.rb -t -n 20 # display 20 notes
```

### My Notest
```
$ misskey.rb -m
$ misskey.rb -m -n 20 # display 20 notes
```

### Post
```
$ misskey.rb -p 'post message'
$ echo 'post message' | misskey.rb -p
$ misskey.rb -p -f <file>
$ misskey.rb -p 'post secret message' -s # secret post
$ misskey.rb -p 'post reply message' -r <note id> # reply to <note id>
```
