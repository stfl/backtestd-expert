//+------------------------------------------------------------------+
//|                                                       Expert.mqh |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertBase.mqh>
#include <Expert\ExpertTrade.mqh>
#include <Expert\ExpertSignal.mqh>
#include <Expert\ExpertMoney.mqh>
#include <Expert\ExpertTrailing.mqh>
#include <Expert\Trailing\TrailingFixedPips.mqh>
#include "Assert.mqh"
#include <backtestd\SignalClass\AggSignal.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_EXPERT_STATE
  {
   NoTrade           =0,
   Long              =10,
   OneCandleLong     =11,
   PullbackLong      =12,
   WaitBaselineLong  =13,
   WaitContinueLong  =14,
   ContinueOneCandleLong=15,
   Short             =20,
   OneCandleShort    =21,
   PullbackShort     =22,
   WaitBaselineShort =23,
   WaitContinueShort =24,
   ContinueOneCandleShort=25,
  };
//+------------------------------------------------------------------+
//| Macro definitions.                                               |
//+------------------------------------------------------------------+
//--- check the expectation of event

//+------------------------------------------------------------------+
//| Class CBacktestExpert.                                                   |
//| Purpose: Base class expert advisor.                              |
//| Derives from class CExpertBase.                                  |
//+------------------------------------------------------------------+
class CBacktestExpert : public CExpertBase
  {
public:
   int               m_period_flags;             // timeframe flags (as visible flags)
   int               m_max_orders;               // max number of orders (include position)
   MqlDateTime       m_last_tick_time;           // time of last tick
   datetime          m_expiration;               // time expiration order
   //--- history info
   int               m_pos_tot;                  // number of open positions
   int               m_deal_tot;                 // number of deals in history
   int               m_ord_tot;                  // number of pending orders
   int               m_hist_ord_tot;             // number of orders in history
   datetime          m_beg_date;                 // start date of history
   //---
   int               m_waiting_event;            // flags of expected trade events
   //--- trading objects
   CExpertTrade      *m_trade;                    // trading object
   CAggSignal        *m_signal;                   // trading signals object
   CExpertMoney      *m_money;                    // money manager object
   // CExpertTrailing  *m_trailing;                 // trailing stops object
   CTrailingFixedPips  *m_trailing;                 // TODO workaround for ATR trailing stop -> include ATR calculation into CTrailingATR
   bool              m_check_volume;             // check and decrease trading volume before OrderSend
   //--- indicators
   CIndicators       m_indicators;               // indicator collection to fast recalculations
   //--- market objects
   CPositionInfo     m_position;                 // position info object
   CPositionInfo     m_position1;
   CPositionInfo     m_position2;
   COrderInfo        m_order;                    // order info object
   CHistoryOrderInfo m_hist_order;
   CDealInfo         m_deal;

   //--- flags of handlers
   bool              m_on_tick_process;          // OnTick will be processed       (default true)
   bool              m_on_trade_process;         // OnTrade will be processed      (default false)
   bool              m_on_timer_process;         // OnTimer will be processed      (default false)
   bool              m_on_chart_event_process;   // PriceCrossEvent will be processed (default false)
   bool              m_on_book_event_process;    // OnBookEvent will be processed  (default false)

   double            m_stop_atr;
   double            m_take_atr;

   ENUM_EXPERT_STATE m_state;
   ENUM_EXPERT_STATE m_next_state;
   uint              m_baseline_wait;
   uint              m_baseline_wait_cnt;
   ulong             m_pos_take;
   ulong             m_pos_open_end;
   double            m_pos_take_tp;
   double            m_pos_take_sl;
   uint              m_take_profit_cnt;
   uint              m_stop_loss_cnt;

   CisNewBar         m_last_bar;

public:
                     CBacktestExpert(void);
                    ~CBacktestExpert(void);
   //--- initialization
   bool              Init(string symbol,ENUM_TIMEFRAMES period,bool every_tick,ulong magic=0);
   void              Magic(ulong value);
   void              CheckVolumeBeforeTrade(const bool flag) { m_check_volume=flag; }
   //--- initialization trading objects
   virtual bool      InitSignal(CExpertSignal *signal=NULL);
   virtual bool      InitTrailing(CTrailingFixedPips *trailing=NULL);
   virtual bool      InitMoney(CExpertMoney *money=NULL);
   virtual bool      InitTrade(ulong magic,CExpertTrade *trade=NULL);
   //--- deinitialization
   virtual void      Deinit(void);
   //--- methods of setting adjustable parameters
   void              OnTickProcess(bool value)              { m_on_tick_process=value;        }
   void              OnTradeProcess(bool value)             { m_on_trade_process=value;       }
   void              OnTimerProcess(bool value)             { m_on_timer_process=value;       }
   void              PriceCrossEventProcess(bool value)        { m_on_chart_event_process=value; }
   void              OnBookEventProcess(bool value)         { m_on_book_event_process=value;  }
   int               MaxOrders(void)                  const { return(m_max_orders);           }
   void              MaxOrders(int value)                   { m_max_orders=value;             }
   //--- methods of access to protected data
   CExpertSignal     *Signal(void) const { return(m_signal);               }
   //--- method of verification of settings
   virtual bool      ValidationSettings();
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators=NULL);
   //--- event handlers
   virtual void      OnTick(void);
   virtual void      OnTrade(void);
   virtual void      OnTimer(void);
   virtual void      PriceCrossEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   virtual void      OnBookEvent(const string &symbol);
   void              StopAtrMultiplier(double value) { m_stop_atr = value; }
   void              TakeAtrMultiplier(double value) { m_take_atr = value; }
   void              BaselineWait(uint value) { m_baseline_wait = value; }
   uint              StopLossCnt(void) { return m_stop_loss_cnt; }
   uint              TakeProfitCnt(void) { return m_take_profit_cnt; }

protected:
   //--- initialization
   virtual bool      InitParameters(void) { return(true); }
   //--- deinitialization
   virtual void      DeinitTrade(void);
   virtual void      DeinitSignal(void);
   virtual void      DeinitTrailing(void);
   virtual void      DeinitMoney(void);
   virtual void      DeinitIndicators(void);
   //--- refreshing
   virtual bool      Refresh(void);
   //--- position select depending on netting or hedging
   virtual bool      SelectPosition(void);
   //--- processing (main method)
   virtual bool      Processing(void);
   //--- trade open positions check
   virtual bool      CheckOpen(void);
   virtual bool      CheckOpenLong(void);
   virtual bool      CheckOpenShort(void);
   //--- trade open positions processing
   virtual bool      OpenLong(double price,double sl,double tp);
   virtual bool      OpenShort(double price,double sl,double tp);
   //--- trade reverse positions check
   virtual bool      CheckReverse(void);
   virtual bool      CheckReverseLong(void);
   virtual bool      CheckReverseShort(void);
   //--- trade reverse positions processing
   virtual bool      ReverseLong(double price,double sl,double tp);
   virtual bool      ReverseShort(double price,double sl,double tp);
   //--- trade close positions check
   virtual bool      CheckClose(void);
   virtual bool      CheckCloseLong(void);
   virtual bool      CheckCloseShort(void);
   //--- trade close positions processing
   virtual bool      CloseAll(double lot);
   virtual bool      Close(void);
   virtual bool      CloseLong(double price);
   virtual bool      CloseShort(double price);
   //--- trailing stop check
   virtual bool      CheckTrailingStop(void);
   virtual bool      CheckTrailingStopLong(void);
   virtual bool      CheckTrailingStopShort(void);
   //--- trailing stop processing
   virtual bool      TrailingStopLong(double sl,double tp);
   virtual bool      TrailingStopShort(double sl,double tp);
   //--- trailing order check
   virtual bool      CheckTrailingOrderLong(void);
   virtual bool      CheckTrailingOrderShort(void);
   //--- trailing order processing
   virtual bool      TrailingOrderLong(double delta);
   virtual bool      TrailingOrderShort(double delta);
   //--- delete order check
   virtual bool      CheckDeleteOrderLong(void);
   virtual bool      CheckDeleteOrderShort(void);
   //--- delete order processing
   virtual bool      DeleteOrders(void);
   virtual bool      DeleteOrdersLong(void);
   virtual bool      DeleteOrdersShort(void);
   virtual bool      DeleteOrder(void);
   virtual bool      DeleteOrderLong(void);
   virtual bool      DeleteOrderShort(void);
   //--- lot for trade
   double            LotOpenLong(double price,double sl);
   double            LotOpenShort(double price,double sl);
   double            LotReverse(double sl);
   double            LotCheck(double volume,double price,ENUM_ORDER_TYPE order_type);
   //--- methods of working with trade history
   void              PrepareHistoryDate(void);
   void              HistoryPoint(bool from_check_trade=false);
   bool              CheckTradeState(void);
   //--- set/reset waiting events
   void              WaitEvent(ENUM_TRADE_EVENTS event)     { m_waiting_event|=event;  }
   void              NoWaitEvent(ENUM_TRADE_EVENTS event)   { m_waiting_event&=~event; }
   //--- trade events
   virtual bool      TradeEventPositionStopTake(void)       { return(true); }
   virtual bool      TradeEventOrderTriggered(void)         { return(true); }
   virtual bool      TradeEventPositionOpened(void)         { return(true); }
   virtual bool      TradeEventPositionVolumeChanged(void)  { return(true); }
   virtual bool      TradeEventPositionModified(void)       { return(true); }
   virtual bool      TradeEventPositionClosed(void)         { return(true); }
   virtual bool      TradeEventOrderPlaced(void)            { return(true); }
   virtual bool      TradeEventOrderModified(void)          { return(true); }
   virtual bool      TradeEventOrderDeleted(void)           { return(true); }
   virtual bool      TradeEventNotIdentified(void)          { return(true); }
   //--- timeframe functions
   void              TimeframeAdd(ENUM_TIMEFRAMES period);
   int               TimeframesFlags(MqlDateTime &time);

   void              PrintTransition(void);
   string            StateName(ENUM_EXPERT_STATE state);
   void              PrintOrders();
   void              PrintPositions();
   void              PrintHistoryByPosition(long position_id);
   void              PrintHistoryOrders();
   void              PrintDeals();
   void              SelectLastOrder(void);
   void              SelectLastOrder(long position_id);
   bool              LastOrderTPHit(long position_id, double tp=0);
   bool              LastOrderSLHit(long position_id, double sl=0);
   bool              OrderTPHit(double tp);
   bool              OrderSLHit(double sl);
   bool              OrderTPHit();
   bool              OrderSLHit();
   bool              MoveBreakEven(long position_id);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBacktestExpert::CBacktestExpert(void) : m_period_flags(0),
   m_expiration(0),
   m_pos_tot(0),
   m_deal_tot(0),
   m_ord_tot(0),
   m_hist_ord_tot(0),
   m_beg_date(0),
   m_trade(NULL),
   m_signal(NULL),
   m_money(NULL),
   m_trailing(NULL),
   m_check_volume(false),
   m_on_tick_process(true),
   m_on_trade_process(false),
   m_on_timer_process(false),
   m_on_chart_event_process(false),
   m_on_book_event_process(false),
   m_max_orders(1),
   m_stop_atr(1.5),
   m_take_atr(1.0),
   m_baseline_wait(7),
   m_pos_take(0),
   m_pos_take_tp(0),
   m_pos_open_end(0),
   m_pos_take_sl(0),
   m_take_profit_cnt(0),
   m_stop_loss_cnt(0),
   m_state(NoTrade)
  {
   m_other_symbol      =true;
   m_other_period      =true;
   m_adjusted_point    =10;
   m_period            =WRONG_VALUE;
   m_last_tick_time.min=-1;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CBacktestExpert::~CBacktestExpert(void)
  {
   Deinit();
  }
//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
bool CBacktestExpert::Init(string symbol,ENUM_TIMEFRAMES period,bool every_tick,ulong magic)
  {
//--- returns false if the EA is initialized on a symbol/timeframe different from the current one
   /* if(symbol!=Symbol() || period!=Period())
    *   {
    *    PrintFormat(__FUNCTION__+": wrong symbol or timeframe (must be %s:%s)",symbol,EnumToString(period));
    *    return(false);
    *   } */
//--- initialize common information
   if(m_symbol==NULL)
     {
      if((m_symbol=new CSymbolInfo)==NULL)
         return(false);
     }
   if(!m_symbol.Name(symbol))
      return(false);
   m_period    =period;
   m_every_tick=every_tick;
   m_magic     =magic;
   SetMarginMode();
   if(every_tick)
      TimeframeAdd(WRONG_VALUE);            // add all periods
   else
      TimeframeAdd(period);                 // add specified period
//--- tuning for 3 or 5 digits
   int digits_adjust=(m_symbol.Digits()==3 || m_symbol.Digits()==5) ? 10 : 1;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
//--- initializing objects expert
   if (!InitTrade(magic, new CExpertTrade)) {
     Print(__FUNCTION__ + ": error initialization trade object");
     return (false);
   }
   if (!InitSignal(new CAggSignal)) {
     Print(__FUNCTION__ + ": error initialization signal object");
     return (false);
   }
   if (!InitTrailing(new CTrailingFixedPips)) {
     Print(__FUNCTION__ + ": error initialization trailing object");
     return (false);
   }
   if (!InitMoney(new CExpertMoney)) {
     Print(__FUNCTION__ + ": error initialization money object");
     return (false);
   }
//--- initialization for working with trade history
   PrepareHistoryDate();
   HistoryPoint();
//--- primary initialization is successful, pass to the phase of tuning
   m_init_phase=INIT_PHASE_TUNING;

   m_last_bar.SetSymbol(m_symbol.Name());
   m_last_bar.SetPeriod(m_period);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Sets magic number for object and its dependent objects           |
//+------------------------------------------------------------------+
void CBacktestExpert::Magic(ulong value)
  {
   if(m_trade!=NULL)
      m_trade.SetExpertMagicNumber(value);
   if(m_signal!=NULL)
      m_signal.Magic(value);
   if(m_money!=NULL)
      m_money.Magic(value);
   if(m_trailing!=NULL)
      m_trailing.Magic(value);
//---
   CExpertBase::Magic(value);
  }
//+------------------------------------------------------------------+
//| Initialization trade object                                      |
//+------------------------------------------------------------------+
bool CBacktestExpert::InitTrade(ulong magic,CExpertTrade *trade)
  {
//--- óäàëÿåì ñóùåñòâóþùèé îáúåêò
   if(m_trade!=NULL)
      delete m_trade;
   m_trade=trade;
//--- tune trade object
   m_trade.SetSymbol(GetPointer(m_symbol));
   m_trade.SetExpertMagicNumber(magic);
   m_trade.SetMarginMode();
//--- set default deviation for trading in adjusted points
   m_trade.SetDeviationInPoints((ulong)(3*m_adjusted_point/m_symbol.Point()));
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization signal object                                     |
//+------------------------------------------------------------------+
bool CBacktestExpert::InitSignal(CExpertSignal *signal)
  {
   if(m_signal!=NULL)
      delete m_signal;
   m_signal=signal;
//--- initializing signal object
   if(!m_signal.Init(GetPointer(m_symbol),m_period,m_adjusted_point))
      return(false);
   m_signal.EveryTick(m_every_tick);
   m_signal.Magic(m_magic);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization trailing object                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::InitTrailing(CTrailingFixedPips *trailing)
  {
   if(m_trailing!=NULL)
      delete m_trailing;
   m_trailing=trailing;
//--- initializing trailing object
   if(!m_trailing.Init(GetPointer(m_symbol),m_period,m_adjusted_point))
      return(false);
// m_trailing.EveryTick(m_every_tick);
   m_trailing.EveryTick(false);   // FIXME -> this needs to go into the trailing class
   m_trailing.Magic(m_magic);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization money object                                      |
//+------------------------------------------------------------------+
bool CBacktestExpert::InitMoney(CExpertMoney *money)
  {
   if(m_money!=NULL)
      delete m_money;
   m_money=money;
//--- initializing money object
   if(!m_money.Init(GetPointer(m_symbol),m_period,m_adjusted_point))
      return(false);
   m_money.EveryTick(m_every_tick);
   m_money.Magic(m_magic);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Validation settings                                              |
//+------------------------------------------------------------------+
bool CBacktestExpert::ValidationSettings(void)
  {
   if(!CExpertBase::ValidationSettings())
      return(false);
//--- Check signal parameters
   if(!m_signal.ValidationSettings())
     {
      Print(__FUNCTION__+": error signal parameters");
      return(false);
     }
//--- Check trailing parameters
   if(!m_trailing.ValidationSettings())
     {
      Print(__FUNCTION__+": error trailing parameters");
      return(false);
     }
//--- Check money parameters
   if(!m_money.ValidationSettings())
     {
      Print(__FUNCTION__+": error money parameters");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization indicators                                        |
//+------------------------------------------------------------------+
bool CBacktestExpert::InitIndicators(CIndicators *indicators)
  {
//--- NULL always comes as the parameter, but here it's not significant for us
   CIndicators *indicators_ptr=GetPointer(m_indicators);
//--- gather information about using of timeseries
   m_used_series|=m_signal.UsedSeries();
   m_used_series|=m_trailing.UsedSeries();
   m_used_series|=m_money.UsedSeries();
//--- create required timeseries
   if(!CExpertBase::InitIndicators(indicators_ptr))
      return(false);

   m_signal.SetPriceSeries(m_open,m_high,m_low,m_close);
   m_signal.SetOtherSeries(m_spread,m_time,m_tick_volume,m_real_volume);
   if(!m_signal.InitIndicators(indicators_ptr))
     {
      Print(__FUNCTION__+": error initialization indicators of signal object");
      return(false);
     }

   m_trailing.SetPriceSeries(m_open,m_high,m_low,m_close);
   m_trailing.SetOtherSeries(m_spread,m_time,m_tick_volume,m_real_volume);
   if(!m_trailing.InitIndicators(indicators_ptr))
     {
      Print(__FUNCTION__+": error initialization indicators of trailing object");
      return(false);
     }

   m_money.SetPriceSeries(m_open,m_high,m_low,m_close);
   m_money.SetOtherSeries(m_spread,m_time,m_tick_volume,m_real_volume);
   if(!m_money.InitIndicators(indicators_ptr))
     {
      Print(__FUNCTION__+": error initialization indicators of money object");
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Deinitialization expert                                          |
//+------------------------------------------------------------------+
void CBacktestExpert::Deinit(void)
  {
//--- delete trade class
   DeinitTrade();
//--- delete signal class
   DeinitSignal();
//--- delete trailing class
   DeinitTrailing();
//--- delete money class
   DeinitMoney();
//--- delete indicators collection
   DeinitIndicators();
  }
//+------------------------------------------------------------------+
//| Deinitialization trade object                                    |
//+------------------------------------------------------------------+
void CBacktestExpert::DeinitTrade(void)
  {
   if(m_trade!=NULL)
     {
      delete m_trade;
      m_trade=NULL;
     }
  }
//+------------------------------------------------------------------+
//| Deinitialization signal object                                   |
//+------------------------------------------------------------------+
void CBacktestExpert::DeinitSignal(void)
  {
   if(m_signal!=NULL)
     {
      delete m_signal;
      m_signal=NULL;
     }
  }
//+------------------------------------------------------------------+
//| Deinitialization trailing object                                 |
//+------------------------------------------------------------------+
void CBacktestExpert::DeinitTrailing(void)
  {
   if(m_trailing!=NULL)
     {
      delete m_trailing;
      m_trailing=NULL;
     }
  }
//+------------------------------------------------------------------+
//| Deinitialization money object                                    |
//+------------------------------------------------------------------+
void CBacktestExpert::DeinitMoney(void)
  {
   if(m_money!=NULL)
     {
      delete m_money;
      m_money=NULL;
     }
  }
//+------------------------------------------------------------------+
//| Deinitialization indicators                                      |
//+------------------------------------------------------------------+
void CBacktestExpert::DeinitIndicators(void)
  {
   m_indicators.Clear();
  }
//+------------------------------------------------------------------+
//| Refreshing data for processing                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::Refresh(void)
  {
   MqlDateTime time;
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- check need processing
   TimeToStruct(m_symbol.Time(),time);
   if(m_period_flags!=WRONG_VALUE && m_period_flags!=0)
      if((m_period_flags&TimeframesFlags(time))==0)
         return(false);
   m_last_tick_time=time;
//--- refresh indicators
   m_indicators.Refresh();
   m_signal.RefreshAtr();
// m_trailing.Refresh();  // FIXME

//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Position select depending on netting or hedging                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::SelectPosition(void)
  {
   bool res=false;
//---
   if(IsHedging())
      res=m_position.SelectByMagic(m_symbol.Name(),m_magic);
   else
      res=m_position.Select(m_symbol.Name());
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| Main function                                                    |
//+------------------------------------------------------------------+
bool CBacktestExpert::Processing(void)
  {
   bool res=false;
   if(Expert_Store_Results == SideChanges)
     {
      // if (!m_signal.AddSideChangeToFrame())
      //    return false;
      if(!m_signal.AddSideChange())
         return false;
      m_signal.UpdateSignal();
     }
   else
     {
      //  calculate signal direction once
      m_signal.Update();
     }

   m_next_state=m_state;

// TODO Rewrite Signal and Side checks below to only access the pre-calculated m_sig_direction and so on
// TODO move this statemachine to AggSignal
// TODO Separate signals for Confirm, Baseline and Continue into separate state machines
   do
     {
      m_state = m_next_state;
      switch(m_state)
        {
         case NoTrade:
            if(m_signal.BaselineSignalLong())
              {
               if(m_signal.LongSide() && m_signal.Volume())
                  m_next_state = Long;
               else
                  if(!m_signal.BaselineATRChannelLong())
                     m_next_state = PullbackLong;
                  else
                    {
                     m_baseline_wait_cnt = 0;
                     m_next_state = WaitBaselineLong;
                    }
              }
            else
               if(m_signal.ConfirmSignalLong())
                 {
                  if(m_signal.LongSide() && m_signal.Volume())
                     m_next_state = Long;
                  else
                     m_next_state = OneCandleLong;
                 }

            if(m_signal.BaselineSignalShort())
              {
               if(m_signal.ShortSide() && m_signal.Volume())
                  m_next_state = Short;
               else
                  if(!m_signal.BaselineATRChannelShort())
                     m_next_state = PullbackShort;
                  else
                    {
                     m_baseline_wait_cnt = 0;
                     m_next_state = WaitBaselineShort;
                    }
              }
            else
               if(m_signal.ConfirmSignalShort())
                 {
                  if(m_signal.ShortSide() && m_signal.Volume())
                     m_next_state = Short;
                  else
                     m_next_state = OneCandleShort;
                 }

            break;

         // ------ Long direction
         case OneCandleLong:
            if(m_signal.LongSide() && m_signal.Volume())
               m_next_state = Long;
            else
               m_next_state = NoTrade;
            break;

         case PullbackLong:
            if(m_signal.BaselineATRChannelLong())
              {
               if(m_signal.LongSide() && m_signal.Volume())
                  m_next_state = Long;
               else
                 {
                  m_baseline_wait_cnt = 0;
                  m_next_state = WaitBaselineLong;
                 }
              }
            else
               m_next_state = NoTrade;
            break;

         case WaitBaselineLong:
            // m_baseline_wait++;
            if(m_signal.BaselineSideShort())
               m_next_state = NoTrade;
            else
               if(m_signal.LongSide() && m_signal.Volume())
                  m_next_state = Long;
               // else if (!m_signal.BaselineATRChannelLong())
               //   m_next_state = NoTrade;
               else
                  if(++m_baseline_wait_cnt >= m_baseline_wait)
                    {
                     m_next_state = NoTrade;
                    }
            break;

         case WaitContinueLong:
            if(m_signal.ConfirmSignalLong())
              {
               if(m_signal.Confirm2SideLong())
                  m_next_state = Long;
               else
                  m_next_state = ContinueOneCandleLong;
              }
            else
               if(m_signal.BaselineSignalShort())
                  m_next_state = NoTrade;
            break;

         case ContinueOneCandleLong:
            if(m_signal.Confirm2SideLong())
               m_next_state = Long;
            else
               if(m_signal.BaselineSignalShort())
                  m_next_state = NoTrade;
               else
                  m_next_state = WaitContinueLong;
            break;

         case Long:
            if(m_signal.BaselineSignalShort())
               m_next_state = NoTrade;
            else
               if(m_signal.ExitSignalShort() || m_signal.ConfirmSignalShort())
                  // m_next_state = WaitContinueLong;
                  m_next_state = NoTrade;
            break;

         // ------------ Short direction
         case OneCandleShort:
            if(m_signal.ShortSide() && m_signal.Volume())
               m_next_state = Short;
            else
               m_next_state = NoTrade;
            break;

         case PullbackShort:
            if(m_signal.BaselineATRChannelShort())
              {
               if(m_signal.ShortSide() && m_signal.Volume())
                  m_next_state = Short;
               else
                 {
                  m_baseline_wait_cnt = 0;
                  m_next_state = WaitBaselineShort;
                 }
              }
            else
               m_next_state = NoTrade;
            break;

         case WaitBaselineShort:
            // m_baseline_wait++;
            if(m_signal.BaselineSideLong())
               m_next_state = NoTrade;
            else
               if(m_signal.ShortSide() && m_signal.Volume())
                  m_next_state = Short;
               // else if (!m_signal.BaselineATRChannelShort())
               //  m_next_state = NoTrade;
               else
                  if(++m_baseline_wait_cnt >= m_baseline_wait)
                    {
                     m_next_state = NoTrade;
                    }
            break;

         case WaitContinueShort:
            if(m_signal.ConfirmSignalShort())
              {
               if(m_signal.Confirm2SideShort())
                  m_next_state = Short;
               else
                  m_next_state = ContinueOneCandleShort;
              }
            else
               if(m_signal.BaselineSignalLong())
                  m_next_state = NoTrade;
            break;

         case ContinueOneCandleShort:
            if(m_signal.Confirm2SideShort())
               m_next_state = Short;
            else
               if(m_signal.BaselineSignalLong())
                  m_next_state = NoTrade;
               else
                  m_next_state = WaitContinueShort;
            break;

         case Short:
            if(m_signal.BaselineSignalLong())
               m_next_state = NoTrade;
            else
               if(m_signal.ExitSignalLong() || m_signal.ConfirmSignalLong())
                  // m_next_state = WaitContinueShort;
                  m_next_state = NoTrade;
            break;

         default:
            // ERROR
            break;
        }
      if(!MQL5InfoInteger(MQL5_OPTIMIZATION))
         PrintTransition();

      if(m_next_state != m_state)
        {
         // there has been a transition
         if(m_state == Long || m_state == Short)
           {
            // Close current trades to allow reverting the direction
            m_pos_take = 0;
            m_pos_open_end = 0;
            m_position = m_position1;
            res = Close();
            if(!Backtest_SingleTrade)
              {
               m_position = m_position2;
               res = Close();
              }
            // assert(res,"Trade did not close properly");
           }
        }

      // on the transition from any state to NoTrade the states are evaluated again
      // to allow reversals and simplify the entier transition matrix
     }
   while(m_next_state != m_state && m_next_state == NoTrade);

   if (m_next_state != m_state) {
     // there has been a transition
     datetime expiration = TimeCurrent() + m_expiration * PeriodSeconds(m_period);
     double atr_value = m_signal.GetAtrValue();

     if (m_next_state == Long) {
       double price = m_symbol.Ask();
       double sl = (m_stop_atr == 0.0) ? 0.0 : price - (m_stop_atr * atr_value);
       double tp = (m_take_atr == 0.0) ? 0.0 : price + (m_take_atr * atr_value);

       // save tp and sl for scale out mechanism
       m_pos_take_tp = tp;
       m_pos_take_sl = sl;

       // m_signal.OpenLongParams(price,sl,tp,expiration);
       if (!m_trade.SetOrderExpiration(expiration))
         m_expiration = expiration;

       double lot = LotOpenLong(price, sl);
       lot = LotCheck(lot, price, ORDER_TYPE_BUY);
       assert(lot != 0.0, "can't open lot");
       m_trade.Buy(lot, price, sl, tp);

       res = m_position.SelectByIndex(PositionsTotal() - 1);
       assert(res, "position was not selected correctly");
       m_pos_take = m_position.Ticket();
       string str;
       Print("watching position: ", m_position.FormatPosition(str));

       if (!Backtest_SingleTrade) {
         double tp2 = ((Backtest_TPOnAllTrades == false) || (m_take_atr == 0.0))
                          ? 0.0
                          : price + (2 * m_take_atr * atr_value);
         m_trade.Buy(lot, price, sl, tp2);
         res = m_position.SelectByIndex(PositionsTotal() - 1);
         assert(res, "position was not selected correctly");
         m_pos_open_end = m_position.Ticket();
         Print("watching position to modify: #", m_position.FormatPosition(str));
       }

     } else if (m_next_state == Short) {
       double price = m_symbol.Bid();
       double sl = (m_stop_atr == 0.0) ? 0.0 : price + (m_stop_atr * atr_value);
       double tp = (m_take_atr == 0.0) ? 0.0 : price - (m_take_atr * atr_value);

       // save tp and sl for scale out mechanism
       m_pos_take_tp = tp;
       m_pos_take_sl = sl;

       if (!m_trade.SetOrderExpiration(expiration))
         m_expiration = expiration;

       double lot = LotOpenShort(price, sl);
       lot = LotCheck(lot, price, ORDER_TYPE_SELL);
       assert(lot != 0.0, "can't open lot");
       m_trade.Sell(lot, price, sl, tp);

       res = m_position.SelectByIndex(PositionsTotal() - 1);
       assert(res, "position was not selected correctly");
       m_pos_take = m_position.Ticket();
       string str;
       Print("watching position: ", m_position.FormatPosition(str));

       if (!Backtest_SingleTrade) {
         double tp2 = ((Backtest_TPOnAllTrades == false) || (m_take_atr == 0.0))
                          ? 0.0
                          : price - (2 * m_take_atr * atr_value);
         m_trade.Sell(lot, price, sl, tp2);
         res = m_position.SelectByIndex(PositionsTotal() - 1);
         assert(res, "position was not selected correctly");
         m_pos_open_end = m_position.Ticket();
         Print("watching position to modify: #", m_position.FormatPosition(str));
       }
     }
     
   }

   m_state=m_next_state;

//--- check if open positions
   if (SelectPosition()) { //--- open position is available
      double atr_pips = m_signal.GetAtrValue() / m_adjusted_point;
      m_trailing.StopLevel((int)MathRound(Money_TrailingStopATRLevel * atr_pips));
      CheckTrailingStop();
   }
//--- TODO check if plased pending orders
   /*
      int total=OrdersTotal();
      if(total!=0)
        {
         for(int i=total-1; i>=0; i--)
           {
            m_order.SelectByIndex(i);
            if(m_order.Symbol()!=m_symbol.Name())
               continue;
            if(m_order.OrderType()==ORDER_TYPE_BUY_LIMIT || m_order.OrderType()==ORDER_TYPE_BUY_STOP)
              {
               //--- check the ability to delete a pending order to buy
               if(CheckDeleteOrderLong())
                  return(true);
               //--- check the possibility of modifying a pending order to buy
               if(CheckTrailingOrderLong())
                  return(true);
              }
            else
              {
               //--- check the ability to delete a pending order to sell
               if(CheckDeleteOrderShort())
                  return(true);
               //--- check the possibility of modifying a pending order to sell
               if(CheckTrailingOrderShort())
                  return(true);
              }
            //--- return without operations
            return(false);
           }
        } */
//--- check the possibility of opening a position/setting pending order
//if(CheckOpen())
//   return(true);
//--- return without operations
   return(res);
  }
//+------------------------------------------------------------------+
//| OnTick handler                                                   |
//+------------------------------------------------------------------+
void CBacktestExpert::OnTick(void)
  {
//--- check process flag
   if(!m_on_tick_process)
      return;
//--- updated quotes and indicators
   if(!Refresh())
      return;

   /* SeriesInfoInteger(m_symbol,m_period,SERIES_LASTBAR_DATE,newbar_time) */
   if((MQL5InfoInteger(MQL5_TESTER) || MQL5InfoInteger(MQL5_OPTIMIZATION)) && !m_every_tick)
     {
      // if we are running on open prices only: assert that we're are looking at the correct bar
      m_last_bar.isNewBar();
      datetime newbar_time = m_last_bar.GetLastBarTime();
      if(TimeCurrent() - newbar_time > 600)
        {
         Print(m_symbol.Name(), " last bar: ", TimeToString(newbar_time, TIME_DATE), " - ", TimeToString(newbar_time, TIME_SECONDS));
         assert(true, "Bar updates for all symbols are not in sync - we are looking at an old bar");
         // the bar is more than 10 minutes old
         // we are probably lookin at yesterdays bar !!!
        }
     }

//--- expert processing
   Processing();
  }
//+------------------------------------------------------------------+
//| OnTrade handler                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::OnTrade(void)
  {
//--- check process flag
   if(!m_on_trade_process)
      return;
//Print("OnTrade: Open Orders:");
//PrintOrders();
//Print("Open Positions:");
//PrintPositions();

   if(m_pos_take!=0)
     {
      PositionSelectByTicket(m_pos_take);
      if(m_pos_take==m_position.Ticket())
        {
         // The position still exists
         //string str;
         //Print("Watching Position still open: ",m_position.FormatPosition(str));
        }
      else
        {
         if(LastOrderTPHit(m_pos_take))
           {
            MoveBreakEven(m_pos_open_end);
            m_pos_take_sl=m_position.PriceOpen();
           }
         else
            if(OrderSLHit()) // history order is already selected
              {
               m_state=NoTrade;
              }
         m_pos_take=0;
        }
     }

   if(m_pos_open_end!=0)
     {
      PositionSelectByTicket(m_pos_open_end);
      // only the position without tp is still running
      if(m_pos_open_end==m_position.Ticket())
        {
         // position still exits
         //string str;
         //Print("Watching open-ended Position still open: ",m_position.FormatPosition(str));
        }
      else
        {
         // position already closed
         if(LastOrderSLHit(m_pos_open_end)) // NOTE: we are using the same stop loss here!!
           {
            m_state=NoTrade;
           }
         m_pos_open_end=0;
        }
      CheckTradeState();
     }
  }
//+------------------------------------------------------------------+
//| OnTimer handler                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::OnTimer(void)
  {
//--- check process flag
   if(!m_on_timer_process)
      return;
  }
//+------------------------------------------------------------------+
//| PriceCrossEvent handler                                             |
//+------------------------------------------------------------------+
void CBacktestExpert::PriceCrossEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
//--- check process flag
   if(!m_on_chart_event_process)
      return;
  }
//+------------------------------------------------------------------+
//| OnBookEvent handler                                              |
//+------------------------------------------------------------------+
void CBacktestExpert::OnBookEvent(const string &symbol)
  {
//--- check process flag
   if(!m_on_book_event_process)
      return;
  }
//+------------------------------------------------------------------+
//| Check for position open or limit/stop order set                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckOpen(void)
  {
   if(CheckOpenLong())
      return(true);
   if(CheckOpenShort())
      return(true);
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for long position open or limit/stop order set             |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckOpenLong(void)
  {
   double   price=EMPTY_VALUE;
   double   sl=0.0;
   double   tp=0.0;
   datetime expiration=TimeCurrent();
//--- check signal for long enter operations
   if(m_signal.CheckOpenLong(price,sl,tp,expiration))
     {
      if(!m_trade.SetOrderExpiration(expiration))
         m_expiration=expiration;
      return(OpenLong(price,sl,tp));
     }
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for short position open or limit/stop order set            |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckOpenShort(void)
  {
   double   price=EMPTY_VALUE;
   double   sl=0.0;
   double   tp=0.0;
   datetime expiration=TimeCurrent();
//--- check signal for short enter operations
   if(m_signal.CheckOpenShort(price,sl,tp,expiration))
     {
      if(!m_trade.SetOrderExpiration(expiration))
         m_expiration=expiration;
      return(OpenShort(price,sl,tp));
     }
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Long position open or limit/stop order set                       |
//+------------------------------------------------------------------+
bool CBacktestExpert::OpenLong(double price,double sl,double tp)
  {
   if(price==EMPTY_VALUE)
      return(false);
//--- get lot for open
   double lot=LotOpenLong(price,sl);
//--- check lot for open
   lot=LotCheck(lot,price,ORDER_TYPE_BUY);
   if(lot==0.0)
      return(false);
//---
   return(m_trade.Buy(lot,price,sl,tp));
  }
//+------------------------------------------------------------------+
//| Short position open or limit/stop order set                      |
//+------------------------------------------------------------------+
bool CBacktestExpert::OpenShort(double price,double sl,double tp)
  {
   if(price==EMPTY_VALUE)
      return(false);
//--- get lot for open
   double lot=LotOpenShort(price,sl);
//--- check lot for open
   lot=LotCheck(lot,price,ORDER_TYPE_SELL);
   if(lot==0.0)
      return(false);
//---
   return(m_trade.Sell(lot,price,sl,tp));
  }
//+------------------------------------------------------------------+
//| Check for position reverse                                       |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckReverse(void)
  {
   if(m_position.PositionType()==POSITION_TYPE_BUY)
     {
      //--- check the possibility of reverse the long position
      if(CheckReverseLong())
         return(true);
     }
   else
     {
      //--- check the possibility of reverse the short position
      if(CheckReverseShort())
         return(true);
     }
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for long position reverse                                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckReverseLong(void)
  {
   double   price=EMPTY_VALUE;
   double   sl=0.0;
   double   tp=0.0;
   datetime expiration=TimeCurrent();
//--- check signal for long reverse operations
   if(m_signal.CheckReverseLong(price,sl,tp,expiration))
      return(ReverseLong(price,sl,tp));
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for short position reverse                                 |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckReverseShort(void)
  {
   double   price=EMPTY_VALUE;
   double   sl=0.0;
   double   tp=0.0;
   datetime expiration=TimeCurrent();
//--- check signal for short reverse operations
   if(m_signal.CheckReverseShort(price,sl,tp,expiration))
      return(ReverseShort(price,sl,tp));
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Long position reverse                                            |
//+------------------------------------------------------------------+
bool CBacktestExpert::ReverseLong(double price,double sl,double tp)
  {
   if(price==EMPTY_VALUE)
      return(false);
//--- get lot for reverse
   double lot=LotReverse(sl);
//--- check lot
   if(lot==0.0)
      return(false);
//---
   bool result=true;
   if(IsHedging())
     {
      //--- first close existing position
      lot-=m_position.Volume();
      result=m_trade.PositionClose(m_position.Ticket());
     }
   if(result)
     {
      lot=LotCheck(lot,price,ORDER_TYPE_SELL);
      if(lot==0.0)
         result=false;
      else
         result=m_trade.Sell(lot,price,sl,tp);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Short position reverse                                           |
//+------------------------------------------------------------------+
bool CBacktestExpert::ReverseShort(double price,double sl,double tp)
  {
   if(price==EMPTY_VALUE)
      return(false);
//--- get lot for reverse
   double lot=LotReverse(sl);
//--- check lot
   if(lot==0.0)
      return(false);
//---
   bool result=true;
   if(IsHedging())
     {
      //--- first close existing position
      lot-=m_position.Volume();
      result=m_trade.PositionClose(m_position.Ticket());
     }
   if(result)
     {
      lot=LotCheck(lot,price,ORDER_TYPE_BUY);
      if(lot==0.0)
         result=false;
      else
         result=m_trade.Buy(lot,price,sl,tp);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Check for position close or limit/stop order delete              |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckClose(void)
  {
   double lot;
//--- position must be selected before call
   if((lot=m_money.CheckClose(GetPointer(m_position)))!=0.0)
      return(CloseAll(lot));
//--- check for position type
   if(m_position.PositionType()==POSITION_TYPE_BUY)
     {
      //--- check the possibility of closing the long position / delete pending orders to buy
      //if(CheckCloseLong())
        {
         DeleteOrdersLong();
         return(true);
        }
     }
   else
     {
      //--- check the possibility of closing the short position / delete pending orders to sell
      //if(CheckCloseShort())
        {
         DeleteOrdersShort();
         return(true);
        }
     }
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for long position close or limit/stop order delete         |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckCloseLong(void)
  {
   double price=EMPTY_VALUE;
//--- check for long close operations
   if(m_signal.CheckCloseLong(price))
      return(CloseLong(price));
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for short position close or limit/stop order delete        |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckCloseShort(void)
  {
   double price=EMPTY_VALUE;
//--- check for short close operations
   if(m_signal.CheckCloseShort(price))
      return(CloseShort(price));
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Position close and orders delete                                 |
//+------------------------------------------------------------------+
bool CBacktestExpert::CloseAll(double lot)
  {
   bool result=false;
//--- check for close operations
   if(IsHedging())
      result=m_trade.PositionClose(m_position.Ticket());
   else
     {
      if(m_position.PositionType()==POSITION_TYPE_BUY)
         result=m_trade.Sell(lot,0,0,0);
      else
         result=m_trade.Buy(lot,0,0,0);
     }
   result|=DeleteOrders();
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Position close                                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::Close(void)
  {
   return(m_trade.PositionClose(m_symbol.Name()));
  }
//+------------------------------------------------------------------+
//| Long position close                                              |
//+------------------------------------------------------------------+
bool CBacktestExpert::CloseLong(double price)
  {
   bool result=false;
//---
   if(price==EMPTY_VALUE)
      return(false);
   if(IsHedging())
      result=m_trade.PositionClose(m_position.Ticket());
   else
      result=m_trade.Sell(m_position.Volume(),price,0,0);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Short position close                                             |
//+------------------------------------------------------------------+
bool CBacktestExpert::CloseShort(double price)
  {
   bool result=false;
//---
   if(price==EMPTY_VALUE)
      return(false);
   if(IsHedging())
      result=m_trade.PositionClose(m_position.Ticket());
   else
      result=m_trade.Buy(m_position.Volume(),price,0,0);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Check for trailing stop/profit position                          |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckTrailingStop(void) {
  //--- position must be selected before call
  if (m_position.PositionType() == POSITION_TYPE_BUY) {
     //--- check the possibility of modifying the long position
     if (CheckTrailingStopLong()) {
        return (true);
     }
  } else {
     //--- check the possibility of modifying the short position
     if (CheckTrailingStopShort()) {
        return (true);
     }
  }
  //--- return without operations
  return (false);
}
//+------------------------------------------------------------------+
//| Check for trailing stop/profit long position                     |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckTrailingStopLong(void)
  {
   double sl=EMPTY_VALUE;
   double tp=EMPTY_VALUE;
//--- check for long trailing stop operations
   if(m_trailing.CheckTrailingStopLong(GetPointer(m_position),sl,tp))
     {
      double position_sl=m_position.StopLoss();
      double position_tp=m_position.TakeProfit();
      if(sl==EMPTY_VALUE)
         sl=position_sl;
      else
         sl=m_symbol.NormalizePrice(sl);
      if(tp==EMPTY_VALUE)
         tp=position_tp;
      else
         tp=m_symbol.NormalizePrice(tp);
      if(sl==position_sl && tp==position_tp)
         return(false);
      //--- long trailing stop operations
      return(TrailingStopLong(sl,tp));
     }
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for trailing stop/profit short position                    |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckTrailingStopShort(void)
  {
   double sl=EMPTY_VALUE;
   double tp=EMPTY_VALUE;
//--- check for short trailing stop operations
   if(m_trailing.CheckTrailingStopShort(GetPointer(m_position),sl,tp))
     {
      double position_sl=m_position.StopLoss();
      double position_tp=m_position.TakeProfit();
      if(sl==EMPTY_VALUE)
         sl=position_sl;
      else
         sl=m_symbol.NormalizePrice(sl);
      if(tp==EMPTY_VALUE)
         tp=position_tp;
      else
         tp=m_symbol.NormalizePrice(tp);
      if(sl==position_sl && tp==position_tp)
         return(false);
      //--- short trailing stop operations
      return(TrailingStopShort(sl,tp));
     }
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Trailing stop/profit long position                               |
//+------------------------------------------------------------------+
bool CBacktestExpert::TrailingStopLong(double sl,double tp)
  {
   bool result;
//---
   if(IsHedging())
      result=m_trade.PositionModify(m_position.Ticket(),sl,tp);
   else
      result=m_trade.PositionModify(m_symbol.Name(),sl,tp);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Trailing stop/profit short position                              |
//+------------------------------------------------------------------+
bool CBacktestExpert::TrailingStopShort(double sl,double tp)
  {
   bool result;
//---
   if(IsHedging())
      result=m_trade.PositionModify(m_position.Ticket(),sl,tp);
   else
      result=m_trade.PositionModify(m_symbol.Name(),sl,tp);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Check for trailing long limit/stop order                         |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckTrailingOrderLong(void)
  {
   double price;
//--- check the possibility of modifying the long order
   if(m_signal.CheckTrailingOrderLong(GetPointer(m_order),price))
      return(TrailingOrderLong(m_order.PriceOpen()-price));
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for trailing short limit/stop order                        |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckTrailingOrderShort(void)
  {
   double price;
//--- check the possibility of modifying the short order
   if(m_signal.CheckTrailingOrderShort(GetPointer(m_order),price))
      return(TrailingOrderShort(m_order.PriceOpen()-price));
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Trailing long limit/stop order                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::TrailingOrderLong(double delta)
  {
   ulong  ticket=m_order.Ticket();
   double price =m_symbol.NormalizePrice(m_order.PriceOpen()-delta);
   double sl    =m_symbol.NormalizePrice(m_order.StopLoss()-delta);
   double tp    =m_symbol.NormalizePrice(m_order.TakeProfit()-delta);
//--- modifying the long order
   return(m_trade.OrderModify(ticket,price,sl,tp,m_order.TypeTime(),m_order.TimeExpiration()));
  }
//+------------------------------------------------------------------+
//| Trailing short limit/stop order                                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::TrailingOrderShort(double delta)
  {
   ulong  ticket=m_order.Ticket();
   double price =m_symbol.NormalizePrice(m_order.PriceOpen()-delta);
   double sl    =m_symbol.NormalizePrice(m_order.StopLoss()-delta);
   double tp    =m_symbol.NormalizePrice(m_order.TakeProfit()-delta);
//--- modifying the short order
   return(m_trade.OrderModify(ticket,price,sl,tp,m_order.TypeTime(),m_order.TimeExpiration()));
  }
//+------------------------------------------------------------------+
//| Check for delete long limit/stop order                           |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckDeleteOrderLong(void)
  {
//--- check the possibility of deleting the long order
   if(m_expiration!=0 && TimeCurrent()>m_expiration)
     {
      m_expiration=0;
      return(DeleteOrderLong());
     }
// if(m_signal.CheckCloseLong(price))
// return(DeleteOrderLong());
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Check for delete short limit/stop order                          |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckDeleteOrderShort(void)
  {
//--- check the possibility of deleting the short order
   if(m_expiration!=0 && TimeCurrent()>m_expiration)
     {
      m_expiration=0;
      return(DeleteOrderShort());
     }
// if(m_signal.CheckCloseShort(price))
// return(DeleteOrderShort());
//--- return without operations
   return(false);
  }
//+------------------------------------------------------------------+
//| Delete all limit/stop orders                                     |
//+------------------------------------------------------------------+
bool CBacktestExpert::DeleteOrders(void)
  {
   bool result=true;
   int  total=OrdersTotal();
//---
   for(int i=total-1; i>=0; i--)
      if(m_order.Select(OrderGetTicket(i)))
        {
         if(m_order.Symbol()!=m_symbol.Name())
            continue;
         result&=DeleteOrder();
        }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Delete all limit/stop long orders                                |
//+------------------------------------------------------------------+
bool CBacktestExpert::DeleteOrdersLong(void)
  {
   bool result=true;
   int  total=OrdersTotal();
//---
   for(int i=total-1; i>=0; i--)
      if(m_order.Select(OrderGetTicket(i)))
        {
         if(m_order.Symbol()!=m_symbol.Name())
            continue;
         if(m_order.OrderType()!=ORDER_TYPE_BUY_STOP &&
            m_order.OrderType()!=ORDER_TYPE_BUY_LIMIT)
            continue;
         result&=DeleteOrder();
        }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Delete all limit/stop orders                                     |
//+------------------------------------------------------------------+
bool CBacktestExpert::DeleteOrdersShort(void)
  {
   bool result=true;
   int  total=OrdersTotal();
//---
   for(int i=total-1; i>=0; i--)
      if(m_order.Select(OrderGetTicket(i)))
        {
         if(m_order.Symbol()!=m_symbol.Name())
            continue;
         if(m_order.OrderType()!=ORDER_TYPE_SELL_STOP &&
            m_order.OrderType()!=ORDER_TYPE_SELL_LIMIT)
            continue;
         result&=DeleteOrder();
        }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Delete limit/stop order                                          |
//+------------------------------------------------------------------+
bool CBacktestExpert::DeleteOrder(void)
  {
   return(m_trade.OrderDelete(m_order.Ticket()));
  }
//+------------------------------------------------------------------+
//| Delete long limit/stop order                                     |
//+------------------------------------------------------------------+
bool CBacktestExpert::DeleteOrderLong(void)
  {
   return(m_trade.OrderDelete(m_order.Ticket()));
  }
//+------------------------------------------------------------------+
//| Delete short limit/stop order                                    |
//+------------------------------------------------------------------+
bool CBacktestExpert::DeleteOrderShort(void)
  {
   return(m_trade.OrderDelete(m_order.Ticket()));
  }
//+------------------------------------------------------------------+
//| Method of getting the lot for open long position.                |
//+------------------------------------------------------------------+
double CBacktestExpert::LotOpenLong(double price,double sl)
  {
   return(m_money.CheckOpenLong(price,sl));
  }
//+------------------------------------------------------------------+
//| Method of getting the lot for open short position.               |
//+------------------------------------------------------------------+
double CBacktestExpert::LotOpenShort(double price,double sl)
  {
   return(m_money.CheckOpenShort(price,sl));
  }
//+------------------------------------------------------------------+
//| Method of getting the lot for reverse position.                  |
//+------------------------------------------------------------------+
double CBacktestExpert::LotReverse(double sl)
  {
   return(m_money.CheckReverse(GetPointer(m_position),sl));
  }
//+------------------------------------------------------------------+
//| Check volume before OrderSend to avoid "not enough money" error  |
//+------------------------------------------------------------------+
double CBacktestExpert::LotCheck(double volume,double price,ENUM_ORDER_TYPE order_type)
  {
   if(m_check_volume)
      return(m_trade.CheckVolume(m_symbol.Name(),volume,price,order_type));
   return(volume);
  }
//+------------------------------------------------------------------+
//| Method of setting the start date for the history.                |
//+------------------------------------------------------------------+
void CBacktestExpert::PrepareHistoryDate(void)
  {
   MqlDateTime dts;
//---
   TimeCurrent(dts);
//--- set up a date at the beginning of the month (but not less than one day)
   if(dts.day==1)
     {
      if(dts.mon==1)
        {
         dts.mon=12;
         dts.year--;
        }
      else
         dts.mon--;
     }
   dts.day =1;
   dts.hour=0;
   dts.min =0;
   dts.sec =0;
//---
   m_beg_date=StructToTime(dts);
  }
//+------------------------------------------------------------------+
//| Method of establishing the checkpoint history.                   |
//+------------------------------------------------------------------+
void CBacktestExpert::HistoryPoint(bool from_check_trade)
  {
//--- check possible recursion
   if(!from_check_trade)
      CheckTradeState();
//--- select history point
   if(HistorySelect(m_beg_date,TimeCurrent()))
     {
      m_hist_ord_tot=HistoryOrdersTotal();
      m_deal_tot    =HistoryDealsTotal();
     }
   else
     {
      m_hist_ord_tot=0;
      m_deal_tot    =0;
     }
   m_ord_tot=OrdersTotal();
   m_pos_tot=PositionsTotal();
  }
//+------------------------------------------------------------------+
//| Method of verification of trade events.                          |
//+------------------------------------------------------------------+
bool CBacktestExpert::CheckTradeState(void)
  {
   bool res=false;
//--- select current history point
   HistorySelect(m_beg_date,INT_MAX);
   int hist_ord_tot=HistoryOrdersTotal();
   int ord_tot     =OrdersTotal();
   int deal_tot    =HistoryDealsTotal();
   int pos_tot     =PositionsTotal();
//--- check for quantitative changes
   if(hist_ord_tot==m_hist_ord_tot && ord_tot==m_ord_tot && deal_tot==m_deal_tot && pos_tot==m_pos_tot)
     {
      //--- no quantitative changes
      if(IS_WAITING_POSITION_MODIFIED)
        {
         res=TradeEventPositionModified();
         NoWaitEvent(TRADE_EVENT_POSITION_MODIFY);
        }
      if(IS_WAITING_ORDER_MODIFIED)
        {
         res=TradeEventOrderModified();
         NoWaitEvent(TRADE_EVENT_ORDER_MODIFY);
        }
      return(true);
     }
//--- check added a pending order
   if(hist_ord_tot==m_hist_ord_tot && ord_tot==m_ord_tot+1 && deal_tot==m_deal_tot && pos_tot==m_pos_tot)
     {
      //--- was added a pending order
      res=TradeEventOrderPlaced();
      //--- establishment of the checkpoint history of the trade
      HistoryPoint(true);
      return(true);
     }
//--- check make a deal "with the market"
   if(hist_ord_tot==m_hist_ord_tot+1 && ord_tot==m_ord_tot)
     {
      //--- was an attempt to make a deal "with the market"
      if(deal_tot==m_deal_tot+1)
        {
         //--- operation successfull
         //--- check position update/subtracting
         if(pos_tot==m_pos_tot)
           {
            //--- position update/subtracting
            if(IS_WAITING_POSITION_VOLUME_CHANGED)
              {
               res=TradeEventPositionVolumeChanged();
               NoWaitEvent(TRADE_EVENT_POSITION_VOLUME_CHANGE);
              }
            //--- establishment of the checkpoint history of the trade
            HistoryPoint(true);
            return(res);
           }
         //--- check position open
         if(pos_tot==m_pos_tot+1)
           {
            //--- position open
            if(IS_WAITING_POSITION_OPENED)
              {
               res=TradeEventPositionOpened();
               NoWaitEvent(TRADE_EVENT_POSITION_OPEN);
              }
            //--- establishment of the checkpoint history of the trade
            HistoryPoint(true);
            return(res);
           }
         //--- check position is closed (including the stoploss/takeprofit)
         if(pos_tot==m_pos_tot-1)
           {

            //--- position is closed (including the stoploss/takeprofit)
            if(IS_WAITING_POSITION_CLOSED)
              {
               res=TradeEventPositionClosed();
               NoWaitEvent(TRADE_EVENT_POSITION_CLOSE);
              }
            else
               res=TradeEventPositionStopTake();
            //--- establishment of the checkpoint history of the trade
            HistoryPoint(true);
            return(res);
           }
        }
      else
        {
         //--- operation failed
         //--- establishment of the checkpoint history of the trade
         HistoryPoint(true);
         return(false);
        }
     }
//--- check delete pending order
   if(hist_ord_tot==m_hist_ord_tot+1 && ord_tot==m_ord_tot-1 && deal_tot==m_deal_tot && pos_tot==m_pos_tot)
     {
      //--- delete pending order
      res=TradeEventOrderDeleted();
      //--- establishment of the checkpoint history of the trade
      HistoryPoint(true);
      return(res);
     }
//--- check triggering of a pending order
   if(hist_ord_tot==m_hist_ord_tot+1 && ord_tot==m_ord_tot-1)
     {
      //--- triggering of a pending order
      if(deal_tot==m_deal_tot+1)
        {
         //--- operation successfull
         //--- check position update/subtracting
         if(pos_tot==m_pos_tot)
           {
            //--- position update/subtracting
            res=TradeEventOrderTriggered();
            //--- establishment of the checkpoint history of the trade
            HistoryPoint(true);
            return(res);
           }
         //--- check position open
         if(pos_tot==m_pos_tot+1)
           {
            //--- position open
            res=TradeEventOrderTriggered();
            //--- establishment of the checkpoint history of the trade
            HistoryPoint(true);
            return(res);
           }
         //--- check position is closed
         if(pos_tot==m_pos_tot-1)
           {
            //--- position is closed
            res=TradeEventOrderTriggered();
            //--- establishment of the checkpoint history of the trade
            HistoryPoint(true);
            return(res);
           }
        }
      else
        {
         //--- operation failed
         //--- establishment of the checkpoint history of the trade
         HistoryPoint(true);
         return(false);
        }
     }
//--- trade event non identifical
   res=TradeEventNotIdentified();
//--- establishment of the checkpoint history of the trade
   HistoryPoint(true);
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| Add timeframe for checked                                        |
//+------------------------------------------------------------------+
void CBacktestExpert::TimeframeAdd(ENUM_TIMEFRAMES period)
  {
   switch(period)
     {
      case PERIOD_M1:
         m_period_flags|=OBJ_PERIOD_M1;
         break;
      case PERIOD_M2:
         m_period_flags|=OBJ_PERIOD_M2;
         break;
      case PERIOD_M3:
         m_period_flags|=OBJ_PERIOD_M3;
         break;
      case PERIOD_M4:
         m_period_flags|=OBJ_PERIOD_M4;
         break;
      case PERIOD_M5:
         m_period_flags|=OBJ_PERIOD_M5;
         break;
      case PERIOD_M6:
         m_period_flags|=OBJ_PERIOD_M6;
         break;
      case PERIOD_M10:
         m_period_flags|=OBJ_PERIOD_M10;
         break;
      case PERIOD_M12:
         m_period_flags|=OBJ_PERIOD_M12;
         break;
      case PERIOD_M15:
         m_period_flags|=OBJ_PERIOD_M15;
         break;
      case PERIOD_M20:
         m_period_flags|=OBJ_PERIOD_M20;
         break;
      case PERIOD_M30:
         m_period_flags|=OBJ_PERIOD_M30;
         break;
      case PERIOD_H1:
         m_period_flags|=OBJ_PERIOD_H1;
         break;
      case PERIOD_H2:
         m_period_flags|=OBJ_PERIOD_H2;
         break;
      case PERIOD_H3:
         m_period_flags|=OBJ_PERIOD_H3;
         break;
      case PERIOD_H4:
         m_period_flags|=OBJ_PERIOD_H4;
         break;
      case PERIOD_H6:
         m_period_flags|=OBJ_PERIOD_H6;
         break;
      case PERIOD_H8:
         m_period_flags|=OBJ_PERIOD_H8;
         break;
      case PERIOD_H12:
         m_period_flags|=OBJ_PERIOD_H12;
         break;
      case PERIOD_D1:
         m_period_flags|=OBJ_PERIOD_D1;
         break;
      case PERIOD_W1:
         m_period_flags|=OBJ_PERIOD_W1;
         break;
      case PERIOD_MN1:
         m_period_flags|=OBJ_PERIOD_MN1;
         break;
      default:
         m_period_flags=WRONG_VALUE;
         break;
     }
  }
//+------------------------------------------------------------------+
//| Forms timeframes flags                                           |
//+------------------------------------------------------------------+
int CBacktestExpert::TimeframesFlags(MqlDateTime &time)
  {
//--- set flags for all timeframes
   int result=OBJ_ALL_PERIODS;
//--- if first check, then setting flags all timeframes
   if(m_last_tick_time.min==-1)
      return(result);
//--- check change time
   if(time.min==m_last_tick_time.min &&
      time.hour==m_last_tick_time.hour &&
      time.day==m_last_tick_time.day &&
      time.mon==m_last_tick_time.mon)
      return(OBJ_NO_PERIODS);
//--- new month?
   if(time.mon!=m_last_tick_time.mon)
      return(result);
//--- reset the "new month" flag
   result^=OBJ_PERIOD_MN1;
//--- new day?
   if(time.day!=m_last_tick_time.day)
      return(result);
//--- reset the "new day" and "new week" flags
   result^=OBJ_PERIOD_D1+OBJ_PERIOD_W1;
//--- temporary variables to speed up working with structures
   int curr,delta;
//--- new hour?
   curr=time.hour;
   delta=curr-m_last_tick_time.hour;
   if(delta!=0)
     {
      if(curr%2>=delta)
         result^=OBJ_PERIOD_H2;
      if(curr%3>=delta)
         result^=OBJ_PERIOD_H3;
      if(curr%4>=delta)
         result^=OBJ_PERIOD_H4;
      if(curr%6>=delta)
         result^=OBJ_PERIOD_H6;
      if(curr%8>=delta)
         result^=OBJ_PERIOD_H8;
      if(curr%12>=delta)
         result^=OBJ_PERIOD_H12;
      return(result);
     }
//--- reset all flags for hour timeframes
   result^=OBJ_PERIOD_H1+OBJ_PERIOD_H2+OBJ_PERIOD_H3+OBJ_PERIOD_H4+OBJ_PERIOD_H6+OBJ_PERIOD_H8+OBJ_PERIOD_H12;
//--- new minute?
   curr=time.min;
   delta=curr-m_last_tick_time.min;
   if(delta!=0)
     {
      if(curr%2>=delta)
         result^=OBJ_PERIOD_M2;
      if(curr%3>=delta)
         result^=OBJ_PERIOD_M3;
      if(curr%4>=delta)
         result^=OBJ_PERIOD_M4;
      if(curr%5>=delta)
         result^=OBJ_PERIOD_M5;
      if(curr%6>=delta)
         result^=OBJ_PERIOD_M6;
      if(curr%10>=delta)
         result^=OBJ_PERIOD_M10;
      if(curr%12>=delta)
         result^=OBJ_PERIOD_M12;
      if(curr%15>=delta)
         result^=OBJ_PERIOD_M15;
      if(curr%20>=delta)
         result^=OBJ_PERIOD_M20;
      if(curr%30>=delta)
         result^=OBJ_PERIOD_M30;
     }
//--- result
   return(result);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::PrintTransition(void)
  {
#ifdef _DEBUG
//             [C: C   CS  C2:C2S B: B   BS  BAC E:  E   V: V  Co: Co
   printf("%6s: [%2s%1s %1s %3s%1s %2s%1s %1s %1s %2s%1s %2s%1s %3s%1s] %13s -> %13s",
          m_symbol.Name(),
          m_signal.ConfirmSignal()== NULL ? " " : "C:",
          m_signal.ConfirmSignal()==NULL ? " " : m_signal.ConfirmSignalLong() ? "▲" : m_signal.ConfirmSignalShort() ? "▼" : " ", // ▲ ▼
          m_signal.ConfirmSignal()== NULL ? " " : m_signal.ConfirmSideLong()        ? "↑" : m_signal.ConfirmSideShort()        ? "↓" : "?",

          m_signal.Confirm2Signal() == NULL ? " " : "C2:",
          m_signal.Confirm2Signal() == NULL ? " " : m_signal.Confirm2SideLong()       ? "↑" : m_signal.Confirm2SideShort()        ? "↓" : "?",

          m_signal.BaselineSignal() == NULL ? " " : "B:",
          m_signal.BaselineSignal() == NULL ? " " : m_signal.BaselineSignalLong()     ? "▲" : m_signal.BaselineSignalShort()     ? "▼" : " ",
          m_signal.BaselineSignal() == NULL ? " " : m_signal.BaselineSideLong()       ? "↑" : m_signal.BaselineSideShort()       ? "↓" : "?",
          m_signal.BaselineSignal() == NULL ? " " : m_signal.BaselineATRChannelLong() ? "√" : m_signal.BaselineATRChannelShort() ? "√" : "X",

          m_signal.ExitSignal()     == NULL ? " " : "E:",
          m_signal.ExitSignal()     == NULL ? " " : m_signal.ExitSignalLong()         ? "▲" : m_signal.ExitSignalShort()         ? "▼" : " ",

          m_signal.VolumeSignal()   == NULL ? " " : "V:",
          m_signal.VolumeSignal()   == NULL ? " " : m_signal.Volume()                 ? "√" : "X",

          m_signal.ContinueSignal()     == NULL ? " " : "Co:",
          m_signal.ContinueSignal()     == NULL ? " " : m_signal.ContinueSignalLong() ? "▲" : m_signal.ContinueSignalShort()         ? "▼" : " ",

          StateName(m_state),
          StateName(m_next_state)
         );
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CBacktestExpert::StateName(ENUM_EXPERT_STATE state)
  {
   return state == NoTrade            ? "NoTrade"
          : state == Long                   ? "Long"
          : state == OneCandleLong          ? "OneCanLong"
          : state == PullbackLong           ? "PullbackLong"
          : state == WaitBaselineLong       ? "BaseLong("+IntegerToString(m_baseline_wait_cnt)+")"
          : state == WaitContinueLong       ? "ContLong"
          : state == ContinueOneCandleLong  ? "ContOneCanLong"
          : state == Short                  ? "Short"
          : state == OneCandleShort         ? "OneCanShort"
          : state == PullbackShort          ? "PullbackShort"
          : state == WaitBaselineShort      ? "BaseShort("+IntegerToString(m_baseline_wait_cnt)+")"
          : state == WaitContinueShort      ? "ContShort"
          : state == ContinueOneCandleShort ? "ContOneCanShort"
          : "Unknown";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::PrintOrders()
  {
#ifdef _DEBUG
   int total=OrdersTotal();
   if(total==0)
      return;

   for(int i=total-1; i>=0; i--)
     {
      m_order.SelectByIndex(i);
      if(m_order.Symbol()!=m_symbol.Name())
         continue;
      string str;
      Print(m_order.FormatOrder(str));
     }
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::PrintHistoryByPosition(long position_id)
  {
   HistorySelectByPosition(position_id);
   Print("History of Position #",position_id,": Orders:");
   PrintHistoryOrders();
   Print("Deals:");
   PrintDeals();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::PrintHistoryOrders()
  {
#ifdef _DEBUG
   int total=HistoryOrdersTotal();
   if(total==0)
      return;

   for(int i=total-1; i>=0; i--)
     {
      m_hist_order.SelectByIndex(i);
      if(m_hist_order.Symbol()!=m_symbol.Name())
         continue;
      string str;
      Print(m_hist_order.FormatOrder(str));
     }
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::PrintDeals()
  {
#ifdef _DEBUG
   int total=HistoryDealsTotal();
   if(total==0)
      return;

   CDealInfo deal;
   for(int i=total-1; i>=0; i--)
     {
      deal.SelectByIndex(i);
      if(deal.Symbol()!=m_symbol.Name())
         continue;
      string str;
      Print(deal.FormatDeal(str));
     }
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::PrintPositions()
  {
#ifdef _DEBUG
   int total=PositionsTotal();
   if(total==0)
      return;

   for(int i=total-1; i>=0; i--)
     {
      m_position.SelectByIndex(i);
      if(m_position.Symbol()!=m_symbol.Name())
         continue;
      string str;
      Print(m_position.FormatPosition(str));
     }
#endif
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::SelectLastOrder()
  {
   HistorySelect(0,TimeCurrent());
   m_hist_order.SelectByIndex(HistoryOrdersTotal()-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CBacktestExpert::SelectLastOrder(long position_id)
  {
   HistorySelectByPosition(position_id);
   m_hist_order.SelectByIndex(HistoryOrdersTotal()-1);

   string str;
   Print("Position #",position_id,
         " Last Order: ",m_hist_order.FormatOrder(str)," \"",m_hist_order.Comment(),"\"");
   Print("tp: ",m_pos_take_tp,
         " sl: ",m_hist_order.StopLoss()," psl:",m_hist_order.PriceStopLimit(),
         " price:",m_hist_order.PriceOpen(),
         " price current:",m_hist_order.PriceCurrent());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::LastOrderTPHit(long position_id,double tp=0)
  {
   SelectLastOrder(position_id);
   return tp==0 ? OrderTPHit() : OrderTPHit(tp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::LastOrderSLHit(long position_id,double sl=0)
  {
   SelectLastOrder(position_id);
   return sl==0 ? OrderSLHit() : OrderSLHit(sl);
  }
//+------------------------------------------------------------------+
//|     Select History Order first                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::OrderTPHit(double tp)
  {
   if(MathAbs(tp-m_hist_order.PriceOpen())<Point())
     {
      Print("=> take profit hit (",++m_take_profit_cnt,")");
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
//|     Select History Order first                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::OrderSLHit(double sl)
  {
   if(MathAbs(sl-m_hist_order.PriceOpen())<Point())
     {
      Print("=> stop loss hit (",++m_stop_loss_cnt,")");
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
//|     Select History Order first                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::OrderTPHit()
  {
   string comment=m_hist_order.Comment();
   StringToLower(comment);
   if(StringFind(comment,"tp")>=0)
     {
      Print("=> take profit hit (",++m_take_profit_cnt,")");
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
//|     Select History Order first                                   |
//+------------------------------------------------------------------+
bool CBacktestExpert::OrderSLHit()
  {
   string comment=m_hist_order.Comment();
   StringToLower(comment);
   if(StringFind(comment,"sl")>=0)
     {
      Print("=> stop loss hit (",++m_stop_loss_cnt,")");
      return true;
     }
   else
      return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CBacktestExpert::MoveBreakEven(long position_id)
  {
   PositionSelectByTicket(position_id);
   if(position_id!=m_position.Ticket())
     {
      Print("position to move break even not found");
      return false;
     }

   return m_trade.PositionModify(m_position.Ticket(),
                                 m_position.PriceOpen(),   // move to break-even
                                 m_position.TakeProfit()); // should be 0.0
  }
//+------------------------------------------------------------------+
