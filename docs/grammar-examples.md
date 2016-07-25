# Grammar examples

## Timestamps

The following grammar allows to parse common formats of timestamps, such as:

* 2009-09-22T06:59:28
* 2009-09-22 06:59:28
* Fri Jun 17 03:50:56 PDT 2011
* 2010-10-26 10:00:53.360

The grammar:

    # Grammar for parsing date, time and timestamps.

    Timestamp <- DateTime / FreeDateTime

    # Times
    Hour <- [0-1] [0-9] / '2' [0-4]
    Minute <- [0-5] [0-9]
    Second <- [0-5] [0-9] / '60'
    Fraction <- ('.' / ',') [0-9]+
    IsoTz <- 'Z' / ('+' / '-') Hour (':'? Minute)?
    TzL <- [A-Z]
    TzAbbr <- TzL TzL (TzL (TzL TzL?)?)?
    TZ <- IsoTz / TzAbbr
    HM <- Hour ':' Minute Fraction?
    HMS <- Hour ':' Minute ':' Second Fraction?
    Time <- ('T' ' '?)? (HMS / HM) (' '? TZ)?

    # Dates
    Year <- [0-9] [0-9] [0-9] [0-9]
    Month <- '0' [1-9] / '1' [0-2]
    Day <- '0' [1-9] / [1-2] [0-9] / '3' [0-1]
    Date <- Year '-' Month ('-' Day)?

    # Combined
    DateTime <- Date ' '? Time

    # Free style
    MonthAbbr <- 'Jan' / 'Feb' / 'Mar' / 'Apr' / 'May' / 'Jun' / 'Jul' / 'Aug' / 'Sep' / 'Sept' / 'Oct' / 'Nov' / 'Dec'
    WeekDayAbbr <- 'Mon' / 'Tu' / 'Tue' / 'Tues' / 'Wed' / 'Th' / 'Thu' / 'Thur' / 'Thurs' / 'Fri' / 'Sat' / 'Sun'
    FreeDateTime <- WeekDayAbbr ' ' MonthAbbr ' ' Day ' ' Time ' ' Year

## CSS syntax

The following grammar allows to parse a subset of CSS syntax, e.g. texts like this:

    body {
      margin: 0;
      padding: 0;
      background: white;
    }

    body, table, form, input, td, th, p, textarea, select
    {
      font-family: Verdana, Helvetica, sans serif;
      font-size: 11px;
    }

(It is not a complete CSS grammar)

    StyleSet <- S Style* EOF
    S <- (Space / Comment)*
    Space <- [ \t\r\n]
    Comment <- '/*' (!'*/' .)* '*/'
    ID <- [a-zA-Z_] IDTail
    IDTail <- [a-zA-Z_0-9]*

    Style <- NameList S PropListStart S PropertyList? PropListEnd S
    NameList <- Name (S ',' S Name)*
    Name <- ID
    PropListStart <- '{'
    PropListEnd <- '}'
    PropertyList <- (Property S ';' S)+

    Property <- PropName S ':' S PropValue

    PropName <- ID ('-' IDTail)*
    PropValue <- ((!';' .) / ';;')*
    EOF <- !.