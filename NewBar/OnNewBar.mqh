//+------------------------------------------------------------------+
//|                                                     OnNewBar.mqh |
//|                                            Copyright 2010, Lizar |
//|                                                    Lizar@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar@mail.ru"

#include <CisNewBar.mqh>
CisNewBar current_chart; // instance of the CisNewBar class: current chart

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int period_seconds=PeriodSeconds(_Period);                     // Number of seconds in current chart period
   datetime new_time=TimeCurrent()/period_seconds*period_seconds; // Time of bar opening on current chart
   if(current_chart.isNewBar(new_time)) OnNewBar();               // When new bar appears - launch the NewBar event handler
  }
