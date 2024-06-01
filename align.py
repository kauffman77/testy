#!/usr/bin/env python3
# from: https://wilkelab.org/classes/SDS348/2019_spring/labs/lab13-solution.html

from difflib import SequenceMatcher

# Use these values to calculate scores
gap_penalty = -0.0
match_award = 1
mismatch_penalty = -1

# Make a score matrix with these two sequences
seq1 = "ATTACATTTTTTTTTGCGCGCATTA"
seq2 = "ATGCTTTTAATATTAAGC"

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

# A function for making a matrix of zeroes
def zeros(rows, cols):
  return [[0]*cols for _ in range(rows)]


# # A function for determining the score between any two bases in alignment
# def match_score(alpha, beta):
#     if alpha == beta:
#         return match_award
#     elif alpha == '-' or beta == '-':
#         raise Exception("WTF^M")
#     else:
#         return mismatch_penalty

# A function for determining the score between any two bases in alignment
def match_score(alpha, beta):
  if alpha == beta:
    return (1.0,"equal")
  else:
    return (SequenceMatcher(None,alpha,beta).quick_ratio(), "replace")


def needleman_wunsch(seq1, seq2):
    
    # Store length of two sequences
    n = len(seq1)  
    m = len(seq2)
    
    # Generate matrix of zeros to store scores
    score = zeros(m+1, n+1)
    trace = zeros(m+1, n+1)
   
    # Calculate score table
    
    # Fill out first column
    for i in range(0, m + 1):
        score[i][0] = gap_penalty * i
        trace[i][0] = "delete"
    
    # Fill out first row
    for j in range(0, n + 1):
        score[0][j] = gap_penalty * j
        trace[0][j] = "insert"
    
    # Fill out all other values in the score matrix
    for i in range(1, m + 1):
        seqmatcher = SequenceMatcher(None,"",seq2[i-1])
        for j in range(1, n + 1):
            (tag,ms) = ("equal",1.0,)
            if seq1[j-1]!=seq2[i-1]:
              seqmatcher.set_seq1(seq1[j-1])
              (tag,ms) = ("replace",seqmatcher.quick_ratio())
              # (tag,ms) = ("replace",seqmatcher.ratio())
            # (ms,tag) = match_score(seq1[j-1], seq2[i-1])
            matchs = (score[i-1][j-1] + ms, (tag,ms))
            delete = (score[i-1][j] + gap_penalty, ("insert",gap_penalty))
            insert = (score[i][j-1] + gap_penalty, ("delete",gap_penalty))
            (sc,tr) = max(matchs, delete, insert)
            score[i][j] = sc
            trace[i][j] = tr
    
    # Traceback and compute the alignment 
    align1 = []
    align2 = []
    diff = []   
    i = m
    j = n
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

    # # We'll use i and j to keep track of where we are in the matrix, just like above
    # while i > 0 and j > 0: # end touching the top or the left edge
    #     score_current = score[i][j]
    #     score_diagonal = score[i-1][j-1]
    #     score_up = score[i][j-1]
    #     score_left = score[i-1][j]
        
    #     # Check to figure out which cell the current score was calculated from,
    #     # then update i and j to correspond to that cell.
    #     if score_current == score_diagonal + match_score(seq1[j-1], seq2[i-1]):
    #         align1.append(seq1[j-1])
    #         align2.append(seq2[i-1])
    #         i -= 1
    #         j -= 1
    #     elif score_current == score_up + gap_penalty:
    #         align1.append(seq1[j-1])
    #         align2.append('-')
    #         j -= 1
    #     elif score_current == score_left + gap_penalty:
    #         align1.append('-')
    #         align2.append(seq2[i-1])
    #         i -= 1

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

def testnw(seq1,seq2):
  (align1,align2,score,diff) = needleman_wunsch(seq1, seq2)
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


