//+------------------------------------------------------------------+
//|                                                       assert.mqh |
//|                                     Copyright 2019, Stefan Lendl |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Stefan Lendl"
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

#ifdef _DEBUG
   #define assert(condition, message) \
      if(!(condition)) \
        { \
         string fullMessage= \
                            #condition+", " \
                            +__FILE__+", " \
                            +__FUNCSIG__+", " \
                            +"line: "+(string)__LINE__ \
                            +(message=="" ? "" : ", "+message); \
         Alert("Assertion failed! "+fullMessage); \
         double x[]; \
         ArrayResize(x, 0); \
         x[1] = 0.0; \
        }
#else 
   #define assert(condition, message) \
      if(!(condition)) {\
         string fullMessage= \
                            #condition+", " \
                            +__FILE__+", " \
                            +__FUNCSIG__+", " \
                            +"line: "+(string)__LINE__ \
                            +(message=="" ? "" : ", "+message); \
         Alert("Assertion failed! "+fullMessage); \
      }
#endif