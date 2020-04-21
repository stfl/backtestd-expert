//+------------------------------------------------------------------+ 
//|                                                 TSI_MACD_HTF.mq5 | 
//|                               Copyright © 2014, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2014, Nikolay Kositsin"
#property link "arria@mail.redcom.ru"
//--- íîìåð âåðñèè èíäèêàòîðà
#property version   "1.60"
#property description "TSI_MACD ñ âîçìîæíîñòüþ èçìåíåíèÿ òàéìôðåéìà âî âõîäíûõ ïàðàìåòðàõ"
//--- îòðèñîâêà èíäèêàòîðà â îòäåëüíîì îêíå
#property indicator_separate_window
//--- êîëè÷åñòâî èíäèêàòîðíûõ áóôåðîâ 2
#property indicator_buffers 2 
//--- èñïîëüçîâàíî îäíî ãðàôè÷åñêîå ïîñòðîåíèå
#property indicator_plots   1
//+----------------------------------------------+
//| îáúÿâëåíèå êîíñòàíò                          |
//+----------------------------------------------+
#define RESET 0                    // Êîíñòàíòà äëÿ âîçâðàòà òåðìèíàëó êîìàíäû íà ïåðåñ÷åò èíäèêàòîðà
#define INDICATOR_NAME "TSI_MACD"  // Êîíñòàíòà äëÿ èìåíè èíäèêàòîðà
#define SIZE 1                     // Êîíñòàíòà äëÿ êîëè÷åñòâà âûçîâîâ ôóíêöèè CountIndicator êîäå
//+----------------------------------------------+
//| Ïàðàìåòðû îòðèñîâêè èíäèêàòîðà 1             |
//+----------------------------------------------+
//--- îòðèñîâêà èíäèêàòîðà â âèäå öâåòíîãî îáëàêà
#property indicator_type1   DRAW_FILLING
//--- â êà÷åñòâå öâåòîâ èíäèêàòîðà èñïîëüçîâàíû
#property indicator_color1  clrDarkTurquoise,clrViolet
//--- îòîáðàæåíèå ìåòêè èíäèêàòîðà
#property indicator_label1  "Signal HTF"
//+----------------------------------------------+
//| Ïàðàìåòðû îòîáðàæåíèÿ ãîðèçîíòàëüíûõ óðîâíåé |
//+----------------------------------------------+
#property indicator_level1 +50
#property indicator_level2   0
#property indicator_level3 -50
#property indicator_levelcolor clrBlue
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| îáúÿâëåíèå ïåðå÷èñëåíèé                      |
//+----------------------------------------------+
enum Smooth_Method
  {
   MODE_SMA_,  // SMA
   MODE_EMA_,  // EMA
   MODE_SMMA_, // SMMA
   MODE_LWMA_, // LWMA
   MODE_JJMA,  // JJMA
   MODE_JurX,  // JurX
   MODE_ParMA, // ParMA
   MODE_T3,    // T3
   MODE_VIDYA, // VIDYA
   MODE_AMA,   // AMA
  };
//+----------------------------------------------+
//| îáúÿâëåíèå ïåðå÷èñëåíèé                      |
//+----------------------------------------------+
enum Applied_price_ //Òèï êîíñòàíòû
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
   PRICE_DEMARK_         //Demark Price
  };
//+----------------------------------------------+
//| Âõîäíûå ïàðàìåòðû èíäèêàòîðà                 |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;
input Smooth_Method XMA_Method=MODE_EMA;
input uint XFast=8;
input uint XSlow=21;
input uint MomPeriod=1;
input uint XLength1=5;
input uint XLength2=8;
input uint XLength3=5;
input int XPhase=15;
//--- XPhase: äëÿ JJMA èçìåíÿþùèéñÿ â ïðåäåëàõ -100 ... +100, âëèÿåò íà êà÷åñòâî ïåðåõîäíîãî ïðîöåññà;
//--- XPhase: äëÿ VIDIA ýòî ïåðèîä CMO, äëÿ AMA ýòî ïåðèîä ìåäëåííîé ñêîëüçÿùåé
input Applied_price_ IPC=PRICE_CLOSE;
input int Shift=0;
//+----------------------------------------------+
//--- îáúÿâëåíèå äèíàìè÷åñêèõ ìàññèâîâ, êîòîðûå â äàëüíåéøåì
//--- áóäóò èñïîëüçîâàíû â êà÷åñòâå èíäèêàòîðíûõ áóôåðîâ
double UpIndBuffer[];
double DnIndBuffer[];
//--- îáúÿâëåíèå öåëî÷èñëåííûõ ïåðåìåííûõ íà÷àëà îòñ÷åòà äàííûõ
int min_rates_total;
//--- îáúÿâëåíèå öåëî÷èñëåííûõ ïåðåìåííûõ äëÿ õåíäëîâ èíäèêàòîðîâ
int Ind_Handle;
//+------------------------------------------------------------------+
//| Ïîëó÷åíèå òàéìôðåéìà â âèäå ñòðîêè                               |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- ïðîâåðêà ïåðèîäîâ ãðàôèêîâ íà êîððåêòíîñòü
   if(!TimeFramesCheck(INDICATOR_NAME,TimeFrame)) return(INIT_FAILED);
//--- èíèöèàëèçàöèÿ ïåðåìåííûõ 
   min_rates_total=2;
//--- ïîëó÷åíèå õåíäëà èíäèêàòîðà TSI_MACD
   Ind_Handle=iCustom(Symbol(),TimeFrame,"TSI_MACD",XMA_Method,XFast,XSlow,MomPeriod,XLength1,XLength2,XLength3,XPhase);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Íå óäàëîñü ïîëó÷èòü õåíäë èíäèêàòîðà TSI_MACD");
      return(INIT_FAILED);
     }
//--- èíèöèàëèçàöèÿ èíäèêàòîðíûõ áóôåðîâ
   IndInit(0,UpIndBuffer,INDICATOR_DATA);
   IndInit(1,DnIndBuffer,INDICATOR_DATA);
//--- èíèöèàëèçàöèÿ èíäèêàòîðîâ
   PlotInit(0,0.0,0,Shift);
//--- ñîçäàíèå èìåíè äëÿ îòîáðàæåíèÿ â îòäåëüíîì ïîäîêíå è âî âñïëûâàþùåé ïîäñêàçêå
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- îïðåäåëåíèå òî÷íîñòè îòîáðàæåíèÿ çíà÷åíèé èíäèêàòîðà
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- çàâåðøåíèå èíèöèàëèçàöèè
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // êîëè÷åñòâî èñòîðèè â áàðàõ íà òåêóùåì òèêå
                const int prev_calculated,// êîëè÷åñòâî èñòîðèè â áàðàõ íà ïðåäûäóùåì òèêå
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- ïðîâåðêà êîëè÷åñòâà áàðîâ íà äîñòàòî÷íîñòü äëÿ ðàñ÷åòà
   if(rates_total<min_rates_total) return(RESET);
   if(BarsCalculated(Ind_Handle)<Bars(Symbol(),TimeFrame)) return(prev_calculated);
//--- èíäåêñàöèÿ ýëåìåíòîâ â ìàññèâàõ êàê â òàéìñåðèÿõ  
   ArraySetAsSeries(time,true);
//---
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,0,UpIndBuffer,1,DnIndBuffer,time,rates_total,prev_calculated,min_rates_total))
      return(RESET);
//---     
   return(rates_total);
  }
//---
//+------------------------------------------------------------------+
//| Èíèöèàëèçàöèÿ èíäèêàòîðíîãî áóôåðà                               |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],ENUM_INDEXBUFFER_TYPE Type)
  {
//--- ïðåâðàùåíèå äèíàìè÷åñêîãî ìàññèâà â èíäèêàòîðíûé áóôåð
   SetIndexBuffer(Number,Buffer,Type);
//--- èíäåêñàöèÿ ýëåìåíòîâ â áóôåðå êàê â òàéìñåðèè
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| Èíèöèàëèçàöèÿ èíäèêàòîðà                                         |
//+------------------------------------------------------------------+    
void PlotInit(int Number,double Empty_Value,int Draw_Begin,int nShift)
  {
//--- îñóùåñòâëåíèå ñäâèãà íà÷àëà îòñ÷åòà îòðèñîâêè èíäèêàòîðà
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- óñòàíîâêà çíà÷åíèé èíäèêàòîðà, êîòîðûå íå áóäóò âèäèìû íà ãðàôèêå
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- îñóùåñòâëåíèå ñäâèãà èíäèêàòîðà ïî ãîðèçîíòàëè íà Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//---
  }
//+------------------------------------------------------------------+
//| CountLine                                                        |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // Íîìåð ôóíêöèè CountLine ïî ñïèñêó â êîäå èíäèêàòîðà (ñòàðòîâûé íîìåð - 0)
                    string   Symb,            // Ñèìâîë ãðàôèêà
                    ENUM_TIMEFRAMES TFrame,   // Ïåðèîä ãðàôèêà
                    int      IndHandle,       // Õåíäë îáðàáàòûâàåìîãî èíäèêàòîðà
                    uint     UpBuffNumb,      // Íîìåð âåðõíåãî áóôåðà îáðàáàòûâàåìîãî èíäèêàòîðà äëÿ îáëàêà
                    double&  UpIndBuf[],      // Ïðèåìíûé âåðõíèé áóôåð èíäèêàòîðà äëÿ îáëàêà
                    uint     DnBuffNumb,      // Íîìåð íèæíåãî áóôåðà îáðàáàòûâàåìîãî èíäèêàòîðà äëÿ îáëàêà
                    double&  DnIndBuf[],      // Ïðèåìíûé íèæíèé áóôåð èíäèêàòîðà äëÿ îáëàêà
                    const datetime& iTime[],  // Òàéìñåðèÿ âðåìåíè
                    const int Rates_Total,    // Êîëè÷åñòâî èñòîðèè â áàðàõ íà òåêóùåì òèêå
                    const int Prev_Calculated,// Êîëè÷åñòâî èñòîðèè â áàðàõ íà ïðåäûäóùåì òèêå
                    const int Min_Rates_Total)// Ìèíèìàëüíîå êîëè÷åñòâî èñòîðèè â áàðàõ äëÿ ðàñ÷åòà
  {
//---
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;
//--- ðàñ÷åòû íåîáõîäèìîãî êîëè÷åñòâà êîïèðóåìûõ äàííûõ
//--- è ñòàðòîâîãî íîìåðà limit äëÿ öèêëà ïåðåñ÷åòà áàðîâ
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// ïðîâåðêà íà ïåðâûé ñòàðò ðàñ÷åòà èíäèêàòîðà
     {
      limit=Rates_Total-Min_Rates_Total-1; // ñòàðòîâûé íîìåð äëÿ ðàñ÷åòà âñåõ áàðîâ
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // ñòàðòîâûé íîìåð äëÿ ðàñ÷åòà íîâûõ áàðîâ 
//--- îñíîâíîé öèêë ðàñ÷åòà èíäèêàòîðà
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- êîïèðóåì âíîâü ïîÿâèâøèåñÿ äàííûå â ìàññèâ IndTime
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);

      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double UpArr[1],DnArr[1];
         //--- êîïèðóåì âíîâü ïîÿâèâøèåñÿ äàííûå â ìàññèâû
         if(CopyBuffer(IndHandle,UpBuffNumb,iTime[bar],1,UpArr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,DnBuffNumb,iTime[bar],1,DnArr)<=0) return(RESET);

         UpIndBuf[bar]=UpArr[0];
         DnIndBuf[bar]=DnArr[0];
        }
      else
        {
         UpIndBuf[bar]=UpIndBuf[bar+1];
         DnIndBuf[bar]=DnIndBuf[bar+1];
        }
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame) //Ïåðèîä ãðàôèêà èíäèêàòîðà (òàéìôðåéì)
  {
//--- ïðîâåðêà ïåðèîäîâ ãðàôèêîâ íà êîððåêòíîñòü
   if(TFrame<Period() && TFrame!=PERIOD_CURRENT)
     {
      Print("Ïåðèîä ãðàôèêà äëÿ èíäèêàòîðà "+IndName+" íå ìîæåò áûòü ìåíüøå ïåðèîäà òåêóùåãî ãðàôèêà!");
      Print("Ñëåäóåò èçìåíèòü âõîäíûå ïàðàìåòðû èíäèêàòîðà!");
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
