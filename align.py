#!/usr/bin/env python3

from difflib import SequenceMatcher


seq1 = [
  "1. Beautiful is better than ugly.",
  "2. Explicit is better than implicit.",
  "3. Simple is better than complex.",
  "4. Complex is better than complicated.",
  "",
  "",
  "cccccccccccccc",
  "ddd  ",
]

seq2 = [
  "1. Beautiful is better than ugly.",
  "",
  "3.   Simple is better than complex.",
  "",
  "4. Complicated is better than complex.",
  "",
  "5. Flat is better than nested.",
  "",
  "aaaaaaaaaaaaaaaa",
  "bbbbbbbbbbbbbbb",
  "cccccccccccccc",
]


def needleman_wunsch(seqA, seqB,
                     scorefunc="RQR",
                     score_range=(-0.25,1.0),
                     gap_cost=-0.1):
  scorefuncs = {                                              # compare seq elements for scoring
    "RQR": lambda seqmatcher: seqmatcher.real_quick_ratio(),  # fastest with least accuracy
    "QR" : lambda seqmatcher: seqmatcher.quick_ratio(),       # fast with more accuracy
    "R"  : lambda seqmatcher: seqmatcher.ratio(),             # slow with high accuracy
  }
  match_score = scorefuncs.get(scorefunc,None)
  if not match_score:
    raise Exception("scorefunc '{scorefunc}' is not known, options are {scorefuncs.keys()}")

  score_scale = score_range[1]-score_range[0]
  score_off   = score_range[0]

  (m,n) = (len(seqA), len(seqB))                     # set up NW score/trace matrix
  scoremat = [[None]*(n+1) for _ in range(m+1)]      # seqA along rows, seqB along cols
  for i in range(0, m + 1):                          # initialize matrices for opening gaps
    scoremat[i][0] = (gap_cost*i,(i,0,"delete",gap_cost))
  for j in range(0, n + 1):
    scoremat[0][j] = (gap_cost*j,(0,j,"insert",gap_cost))
  
  # MAIN SCORING ALGORITHM
  for i in range(1, m+1):
    seqmatcher = SequenceMatcher(None,"",seqA[i-1])  # seqmatcher optimized for stable seq2, vary seq1 more frequentyly
    for j in range(1, n + 1):
      if seqA[i-1]==seqB[j-1]:                       # equal elems score a 1.0
        (tag,raw_score) = ("equal",1.0)
      else:                                          # unequal elems score in range -0.2 to 1.0
        seqmatcher.set_seq1(seqB[j-1])               # use seqmatcher for comparison 
        (tag,raw_score) = ("replace",match_score(seqmatcher))
      mscore = raw_score*score_scale + score_off                     # scale the score in range
      scores = ((scoremat[i-1][j-1][0] + mscore,(i-1,j-1,tag,mscore)),         # match seq1/2 elem  
                (scoremat[i-1][j][0] + gap_cost,(i-1,j,"insert",gap_cost)),  # insert seq2 elem   
                (scoremat[i][j-1][0] + gap_cost,(i,j-1,"delete",gap_cost)))  # delete seq1 elem   
      scoremat[i][j] = max(scores)
  
  # TRACEBACK COMPUTATION
  align_score = scoremat[-1][-1][0]              # overall score of the global alignmnet
  align = []                                     # traceback alignment, elements (seq1,seq2,tag,cost)
  i,j = m,n
  while i > 0 or j > 0:
    (_,info) = scoremat[i][j]
    align.append(info)
    i=info[0]
    j=info[1]

  align.reverse()                                # reverse the alignment in place
  return (align, align_score)


def testnw(seq1,seq2):
  (align,score) = needleman_wunsch(seq1, seq2, scorefunc="RQR")
  print(f"score: {score:+5.2f} len: {len(align)}")
  width1 = max([len(seq1[s1])
                for (s1,s2,tag,_) in align
                if tag in {"equal","replace","delete"}])
  width2 = max([len(seq2[s2])
                for (s1,s2,tag,_) in align
                if tag in {"equal","replace","insert"}])
  for s1,s2,tag,cost in align:
    if tag=="delete":
      print(f"{seq1[s1]:{width1}} {tag:{8}} {cost:+5.2f} {'':{width2}}")
    elif tag=="insert":
      print(f"{'':{width1}} {tag:{8}} {cost:+5.2f} {seq2[s2]:{width2}}")
    else:
      print(f"{seq1[s1]:{width1}} {tag:{8}} {cost:+5.2f} {seq2[s2]:{width2}}")



# has an inverted seq1 len=n / seq2 len=m
def needleman_wunsch3(seq1, seq2,
                     scorefunc="RQR",
                     score_range=(-0.25,1.0),
                     gap_cost=-0.1):
  scorefuncs = {                                              # compare seq elements for scoring
    "RQR": lambda seqmatcher: seqmatcher.real_quick_ratio(),  # fastest with least accuracy
    "QR" : lambda seqmatcher: seqmatcher.quick_ratio(),       # fast with more accuracy
    "R"  : lambda seqmatcher: seqmatcher.ratio(),             # slow with high accuracy
  }
  match_score = scorefuncs.get(scorefunc,None)
  if not match_score:
    raise Exception("scorefunc '{scorefunc}' is not known, options are {scorefuncs.keys()}")

  score_scale = score_range[1]-score_range[0]
  score_off   = score_range[0]

  (n,m) = (len(seq1), len(seq2))                     # set up NW score/trace matrix
  scoremat = [[None]*(n+1) for _ in range(m+1)]      # seq1 along columns, seq2 along rows
  for i in range(0, m + 1):                          # initialize matrices for opening gaps
    scoremat[i][0] = (gap_cost*i,(i,0,"delete",gap_cost))
  for j in range(0, n + 1):
    scoremat[0][j] = (gap_cost*j,(0,j,"insert",gap_cost))
  
  # MAIN SCORING ALGORITHM
  for i in range(1, m + 1):                          
    seqmatcher = SequenceMatcher(None,"",seq2[i-1])  # seqmatcher optimized for stable seq2, vary seq1 more frequentyly
    for j in range(1, n + 1):
      if seq1[j-1]==seq2[i-1]:                       # equal elems score a 1.0
        (tag,raw_score) = ("equal",1.0)
      else:                                          # unequal elems score in range -0.2 to 1.0
        seqmatcher.set_seq1(seq1[j-1])               # use seqmatcher for comparison 
        (tag,raw_score) = ("replace",match_score(seqmatcher))
      mscore = raw_score*score_scale + score_off                     # scale the score in range
      scores = ((scoremat[i-1][j-1][0] + mscore,(i-1,j-1,tag,mscore)),         # match seq1/2 elem  
                (scoremat[i-1][j][0] + gap_cost,(i-1,j,"insert",gap_cost)),  # insert seq2 elem   
                (scoremat[i][j-1][0] + gap_cost,(i,j-1,"delete",gap_cost)))  # delete seq1 elem   
      scoremat[i][j] = max(scores)
  
  # TRACEBACK COMPUTATION
  align_score = scoremat[-1][-1][0]              # overall score of the global alignmnet
  align = []                                     # traceback alignment, elements (seq1,seq2,tag,cost)
  i,j = m,n
  while i > 0 or j > 0:
    (_,info) = scoremat[i][j]
    align.append(info)
    i=info[0]
    j=info[1]

  align.reverse()                                # reverse the alignment in place
  return (align, align_score)

def testnw3(seq1,seq2):
  (align,score) = needleman_wunsch(seq1, seq2, scorefunc="RQR")
  print(f"score: {score:+5.2f} len: {len(align)}")
  width1 = max([len(seq1[s1])
                for (s2,s1,tag,_) in align
                if tag in {"equal","replace","delete"}])
  width2 = max([len(seq2[s2])
                for (s2,s1,tag,_) in align
                if tag in {"equal","replace","insert"}])
  for s2,s1,tag,cost in align:
    if tag=="delete":
      print(f"{seq1[s1]:{width1}} {tag:{8}} {cost:+5.2f} {'':{width2}}")
    elif tag=="insert":
      print(f"{'':{width1}} {tag:{8}} {cost:+5.2f} {seq2[s2]:{width2}}")
    else:
      print(f"{seq1[s1]:{width1}} {tag:{8}} {cost:+5.2f} {seq2[s2]:{width2}}")


def needleman_wunsch2(seq1, seq2, gap_cost=-0.1, scorefunc="QR"):
    scorefuncs = {
      "RQR": lambda seqmatcher: seqmatcher.real_quick_ratio(),
      "QR" : lambda seqmatcher: seqmatcher.quick_ratio(),
      "R"  : lambda seqmatcher: seqmatcher.ratio(),
    }
    match_score = scorefuncs.get(scorefunc,None)
    if not match_score:
      raise Exception("scorefunc '{scorefunc}' is not known, options are {scorefuncs.keys()}")

    # set up NW score/trace matrices
    n = len(seq1)  
    m = len(seq2)
    score = [[None]*(n+1) for _ in range(m+1)]
    trace = [[None]*(n+1) for _ in range(m+1)]
   
    # initialize matrices for opening gaps
    for i in range(0, m + 1):
        score[i][0] = gap_cost * i
        trace[i][0] = "delete"
    for j in range(0, n + 1):
        score[0][j] = gap_cost * j
        trace[0][j] = "insert"
    
    for i in range(1, m + 1):
        seqmatcher = SequenceMatcher(None,"",seq2[i-1])
        for j in range(1, n + 1):
            if seq1[j-1]==seq2[i-1]:             # equal elems score a 1.0
              (tag,mscore) = ("equal",1.0)
            else:                                # unequal sequences score
              seqmatcher.set_seq1(seq1[j-1])     # in range -0.2 to 1.0
              tag = "replace"                    # using a comparison function
              mscore = match_score(seqmatcher)*1.25-0.25
            (sc,tr) = max((score[i-1][j-1] + mscore, (tag,mscore)),         # match seq1/2 elem
                          (score[i-1][j] + gap_cost, ("insert",gap_cost)),  # insert seq2 elem
                          (score[i][j-1] + gap_cost, ("delete",gap_cost)))  # delete seq1 elem
            score[i][j] = sc
            trace[i][j] = tr
    
    # Traceback and compute the alignment 
    align1 = []
    align2 = []
    diff = []   
    i = m
    j = n
    # for i,r in enumerate(trace):
    #   for j,c in enumerate(r):
    #     print(f"({i:{2}},{j:{2}}) {c}")
    while i > 0 or j > 0:
        (tag,scr) = trace[i][j]
        diff.append((tag,scr))
        if tag=="equal" or tag=="replace":
            align1.append(seq1[j-1])
            align2.append(seq2[i-1])
            i -= 1
            j -= 1
        elif tag=="delete":
            align1.append(seq1[j-1])
            align2.append('-')
            j -= 1
        elif tag=="insert":
            align1.append('-')
            align2.append(seq2[i-1])
            i -= 1
        else:
            raise Exception("Problem in traceback")

    # Finish tracing up to the top left cell
    while j > 0:
        align1 += seq1[j-1]
        align2 += '-'
        j -= 1
    while i > 0:
        align1 += '-'
        align2 += seq2[i-1]
        i -= 1
    
    # Since we traversed the score matrix from the bottom right, our two sequences will be reversed.
    # These two lines reverse the order of the characters in each sequence.
    align1 = align1[::-1]
    align2 = align2[::-1]
    diff = diff[::-1]
    
    return(align1, align2, score[-1][-1], diff)

def testnw2(seq1,seq2):
  (align1,align2,score,diff) = needleman_wunsch2(seq1, seq2, scorefunc="QR")
  print(f"score: {score} lens: {len(align1)} {len(align2)} {len(diff)}")

  width1 = max([len(x) for x in align1])
  for s1,s2,(dt,ds) in zip(align1,align2,diff):
    print(f"{s1:{width1}} {dt:{8}} {ds:+5.2f} {s2}")

  


################################################################################
# Main Entry point
if __name__ == '__main__':
  with open("prob1-20-expect.tmp") as f:
    seq1 = f.read().splitlines()
  with open("prob1-20-actual2.tmp") as f:
    seq2 = f.read().splitlines()
  testnw(seq1,seq2)


