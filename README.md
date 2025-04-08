<H1>SIMPLE-MT-Trading-Framework</H1>
<br>This is a framwork to host code, initially intended for mt4/mt5 platforms on Atetrprime broker. In theory, because code is OO driven,  other platforms can be included too , eg. CTtrader (C#) , Trade Evolution (c#) or TradingView (PineScript).
This was knocked up over a weekend using Grok AI.
<br>Not fully tested

<h2>Expected Behavior</h2>
Basic Mode (Option 1): Creates strategy folders with sample .mq4/.mq5 files (manual compilation required).
Advanced Mode (Option 2): Uses Docker to compile .mq4 to .ex4 and .mq5 to .ex5, placing them in MQL4/MQL5 subfolders, ready for MT4/MT5 use.
