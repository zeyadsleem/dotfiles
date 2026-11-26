[Appearance]
# Palette is regenerated from the Noctalia theme by
# .config/noctalia/hooks/konsole-palette.sh.
ColorScheme=noctalia
# Matches kitty: Maple Mono NF Medium at 11pt, which Konsole renders at the
# same 9px cell width as kitty font_size 11.3 with cell_width 105%.
Font=Maple Mono NF Medium,11,-1,5,50,0,0,0,0,0
# LineSpacing is extra pixels per line, not a percentage: 20px is Konsole's
# natural pitch for this font. 4px gives a 24px cell, the same cell height
# ptyxis renders (11.3pt at 115%), and at the maximized 992px height 41 cells
# fit the content area exactly, leaving the same 4px bottom gap as ptyxis.
LineSpacing=4

[General]
Name=noctalia
Parent=FALLBACK/
# Uniform padding; ptyxis used 4px.
TerminalMargin=4

[Scrolling]
# FixedSizeHistory, not UnlimitedHistory: agent logs must not grow forever.
HistoryMode=1
HistorySize=10000
ScrollBarPosition=2

[Terminal Features]
# ICU bidi: the reason Konsole replaced VTE for Arabic.
BidiRenderingEnabled=true
# "force LTR line direction" — must stay false, otherwise every line is laid
# out left-to-right regardless of content and Arabic renders LTR. With false,
# each line's base direction comes from its first strongly directional
# character, so Arabic lines are RTL and Latin ones stay LTR.
BidiLineLTR=false
