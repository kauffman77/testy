class OrgSuiteParser:
  """Handle Emacs Org formatted files"""

  def parse_file(self,filename):
    """Parse an Emacs Org formatted files

    Org files are the traditional format to create readable, compact
    test files. This function parses an Org file and builds a Suite
    from it.
    """

    contents = ""
    with open(filename,encoding='utf-8') as f:
      contents = str(f.read())  # slurp the file into memory

    # test file comprises a premble which ends at the first '* test
    # title' and follows an overall pattern of title / contents for
    # the remainder
    parts = re.split(re.compile(r"(^\* .*$)",re.MULTILINE), contents)

    preamble = parts[0]               # preceding the first test, stuff like #+title
    # titles   = parts[1:len(parts):2]  # titles of each test
    # contents = parts[2:len(parts):2]  # contents of each test
    titles_contents = zip(parts[1:len(parts):2],parts[2:len(parts):2])

    suite = Suite()                        # suite to be built
    preamble_comments = []                 # comment lines accumulated in the preamble
    linenum = 0                            # line number of parsing for bug reporting

    try:
      # PREAMBLE parsing preceding the first test
      for line in preamble.splitlines():
        lineum += 1                          # track line number for error reporting
        (first,rest) = ("",line)
        if " " in line:
          (first, rest) = line.split(" ",1)  # extract the first token on the line
          first = first.upper()              # upper case for case insensitive matching

        if first == "#+TITLE:":              # title as in [#+TITLE: Tests for blather]
          suite.title = rest

        elif first == "#+TESTY:":            # option directive like [#+TESTY: program='bc -iq']
          (key,val) = get_keyval(rest)       # may throw if badly formatted
          if key in suite.__dict__:
            suite.__dict__[key] = val        # python objects are dicts, exploit this to assign the value
          else:
            suite.test_opts[key] = val
        else:
          preamble_comments.append(line)     # not a directive or key val, append to comments

      while preamble_comments[-1] == "":     # remove trailing blank lines from preamble comments
        preamble_comments.pop()

      suite.comments = "\n".join(preamble_comments)

      # TEST HANDLING which begins at the first [* Test Name]
      for (test_title,content) in titles_contents:
        linenum += 1                         # test title is on next line
        test = Test()
        suite.tests.append(test)             # add in empty test to the
        test.title = test_title
        propogate_fields(test, suite.test_opts)

        # TODO handle :PROPERTIES: drawer here with test-specific properties

        # Iterate over each segment each of which is a pair of
        # preamble/session. This is a little complicated but iterating
        # in this way makes it easier to keep track of hte global line
        # number to do error reporting
        content_lines = content.splitlines()
        seg_count = len([x for x in content_lines
                         if (x.upper.startswith("#+BEGIN_SRC") or
                             x.upper.startswith("#+BEGIN_QUOTE"))])
        i = -1
        for _ in range(seg_count):
          segment = Segment()
          comment_lines = []
          test.segments.append(segment)
          propogate_fields(segment, suite.test_opts)

          # parse the segment preamble
          begin_token = ""
          while True:
            i += 1
            line = content_lines[i]
            linenum += 1
            (first,rest) = ("",line)
            if " " in line:
              (first, rest) = line.split(" ",1)     # extract the first token on the line
              first = first.upper()                 # upper case for case insensitive matching

            # handle lines the suite
            if first in {"#+BEGIN_SRC","#+BEGIN_QUOTE"}:
              begin_token = first                   # end of preamble, go to next loop
              break
            if first=="#+TESTY:" and rest[0]=="!":  # shell command as in [#+TESTY: !rm file.txt]
              segment.commands.append(rest[1:])     # peel off the ! at the start
            elif first == "#+TESTY:":
              (key,val) = get_keyval(rest)          # may throw if badly formatted
              segment.__dict__[key] = val
            else:
              comment_lines.append(line)
          # finished parsing preamble

          # parse the session for this segment
          end_token = {"#+BEGIN_SRC"   : "#+END_SRC",
                       "#+BEGIN_QUOTE" : "#+END_QUOTE"}[begin_token]
          session_lines = []
          while True:
            i += 1
            line = content_lines[i]
            linenum += 1
            if line.upper.startswith(end_token):
              break
            session_lines.append(line)
          # end session parsing
        # end loop over segments

        # update global line position for any trailing lines after the session
        linenum += len(content_lines)-i
      # END loop over tests

    except Exception as e:                 # decorate any parsing errors with a file/line number
      raise Exception(f"{filename}:{linenum} {str(e)}") from e
