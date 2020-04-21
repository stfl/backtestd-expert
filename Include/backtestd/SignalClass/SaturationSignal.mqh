//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+

enum ENUM_REGION {
  InitRegion,
  NeutralRegion,
  LongRegion,
  ShortRegion,
};

class CSaturationSignal : public CCustomSignal {
protected:
  ENUM_REGION m_region;
  ENUM_REGION m_last_region;
  bool m_signal_on_region_leave;

  //                                  strict = true            strict == false
  //                                  x <- LongSide            x <- LongSide
  // Level Up enter   ▲----
  //                                  x <- None                ▼ <- LongSide
  // Level Up exit    ▼----
  //                                  x <- None                x <- None
  // Level Down exit  ▲----
  //                                  x <- None                ▲ <- ShortSide
  // Level Down enter ▼----
  //                                  x <- ShortSide           x <- ShortSide

  // if down enter is higher than up enter
  // his case always represents non strict side
  //                                                x  LongSide
  // Level Down enter == Down exit  ▼----
  //                                                ▼ LongSide  ▲ ShortSide
  // Level Up enter == Up exit      ▲----
  //                                                x <- ShortSide

public:
  virtual bool Update(void);
  virtual ENUM_REGION UpdateRegion(void) { return m_region; }
  CSaturationSignal(void);

protected:
  virtual bool UpdateLongSignal(void);
  virtual bool UpdateShortSignal(void);
};

CSaturationSignal::CSaturationSignal(void) {
  m_region = m_last_region = InitRegion;
  m_signal_on_region_leave = false;
}

bool CSaturationSignal::UpdateLongSignal(void) {
  if (m_signal_on_region_leave) {
    if (m_last_region == LongRegion &&
        (m_region == NeutralRegion || m_region == ShortRegion)) {
      m_state = SignalLong;
      m_sig_direction = 1;
      m_exit_direction = 1;
      return true;
    }
  } else {
    if (m_region == LongRegion &&
        (m_last_region == NeutralRegion || m_last_region == ShortRegion)) {
      m_state = SignalLong;
      m_sig_direction = 1;
      m_exit_direction = 1;
      return true;
    }
  }
  return false;
}

bool CSaturationSignal::UpdateShortSignal(void) {
  if (m_signal_on_region_leave) {
    if (m_last_region == ShortRegion &&
        (m_region == NeutralRegion || m_region == LongRegion)) {
      m_state = SignalShort;
      m_sig_direction = -1;
      m_exit_direction = -1;
      return true;
    }
  } else { // on region enter
    if (m_region == ShortRegion &&
        (m_last_region == NeutralRegion || m_last_region == LongRegion)) {
      m_state = SignalShort;
      m_sig_direction = -1;
      m_exit_direction = -1;
      return true;
    }
  }
  return false;
}

bool CSaturationSignal::Update() {
  m_sig_direction = 0;
  m_exit_direction = 0;
  m_last_region = m_region;

  UpdateRegion();
  UpdateLongSignal();
  UpdateShortSignal();
  UpdateSide();
  return true;
}
