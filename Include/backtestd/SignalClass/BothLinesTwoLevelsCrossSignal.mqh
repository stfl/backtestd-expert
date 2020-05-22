//+------------------------------------------------------------------+
//|                                     Copyright 2019, Stefan Lendl |
//+------------------------------------------------------------------+
#include "CustomSignal.mqh"
//+------------------------------------------------------------------+
class CBothLinesTwoLevelsCrossSignal : public CCustomSignal {
protected:
  CIndicatorBuffer *m_buf_up;
  CIndicatorBuffer *m_buf_down;
  double m_level_up_enter;
  double m_level_up_exit;
  double m_level_down_enter;
  double m_level_down_exit;

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
  //--- methods of checking if the market models are formed
  // bool LongSide(void);
  // bool ShortSide(void);
  virtual bool Update(void);

  //CBothLinesTwoLevelsCrossSignal(void);

protected:
  virtual bool UpdateLongSignal(void);
  virtual bool UpdateShortSignal(void);
  virtual bool UpdateLongExit(void);
  virtual bool UpdateShortExit(void);

  virtual bool UpdateShortReturn(void);
  virtual bool UpdateLongReturn(void);

  virtual bool UpdateStrictSide(void);

  virtual bool UpdateSide(void);

  virtual bool InitIndicatorBuffers();
};

//CBothLinesTwoLevelsCrossSignal::CBothLinesTwoLevelsCrossSignal(void) {}

bool CBothLinesTwoLevelsCrossSignal::UpdateSide(void) {
  switch (m_state) {
  // case Init:
  //    m_side = EMPTY_VALUE;
  case SignalNoTrade:
    m_side = 0;
    break;
  case SignalLongReturn:
  case SignalLong:
    m_side = 100;
    break;
  case SignalShortReturn:
  case SignalShort:
    m_side = -100;
    break;
  }
  return true;
}

// bool CBothLinesTwoLevelsCrossSignal::LongSide(void) {
//   int idx = StartIndex();
//   if (m_stateful_side) {
//     UpdateLongSignal(); // calculate Signal in case we don't have
//     m_last_signal set
//     // yet.
//     return m_last_signal > 0; // consider the last signal
//   } else {
//     if (m_buf_up.At(idx) > m_level_up_enter &&
//         m_buf_down.At(idx) > m_level_up_enter) {
//       // if both lines are on the up side, there has been a signal at some
//       point
//       // we need to set this here in order to ensure a first initialization
//       of
//       // m_last_signal
//       // m_last_signal = 100;
//       return true;
//     } else
//       return false;
//   }
// }

// bool CBothLinesTwoLevelsCrossSignal::ShortSide(void) {
//   int idx = StartIndex();
//   if (m_stateful_side) {
//     UpdateShortSignal(); // calculate Signal in case we don't have
//     m_last_signal set
//     // yet.
//     return m_last_signal < 0; // consider the last signal
//   } else {
//     if (m_buf_down.At(idx) < m_level_down_enter &&
//         m_buf_up.At(idx) < m_level_down_enter) {
//       // m_last_signal = -100;
//       return true;
//     } else
//       return false;
//   }
// }

bool CBothLinesTwoLevelsCrossSignal::UpdateLongSignal(void) {
  int idx = StartIndex();
  if ((m_buf_up.At(idx) > m_level_up_enter &&
       m_buf_down.At(idx) > m_level_up_enter) &&
      (m_buf_up.At(idx + 1) <= m_level_up_enter ||
       m_buf_down.At(idx + 1) <= m_level_up_enter)) {

    m_sig_direction = 1;
    m_state = SignalLong;
    return true;
  }
  return false;
}

bool CBothLinesTwoLevelsCrossSignal::UpdateShortSignal(void) {
  int idx = StartIndex();
  if ((m_buf_up.At(idx) <= m_level_down_enter &&
       m_buf_down.At(idx) <= m_level_down_enter) &&
      (m_buf_up.At(idx + 1) > m_level_down_enter ||
       m_buf_down.At(idx + 1) > m_level_down_enter)) {

    m_sig_direction = -1;
    m_state = SignalShort;
    return true;
  }
  return false;
}

bool CBothLinesTwoLevelsCrossSignal::UpdateLongExit(void) {
  int idx = StartIndex();
  if ((m_buf_up.At(idx) <= m_level_up_exit &&
       m_buf_down.At(idx) <= m_level_up_exit) &&
      (m_buf_up.At(idx + 1) > m_level_up_exit ||
       m_buf_down.At(idx + 1) > m_level_up_exit)) {

    m_exit_direction = -1;
    m_state = SignalNoTrade;
    return true;
  }
  return false;
}

bool CBothLinesTwoLevelsCrossSignal::UpdateShortExit(void) {
  int idx = StartIndex();
  if ((m_buf_up.At(idx) > m_level_down_exit &&
       m_buf_down.At(idx) > m_level_down_exit) &&
      (m_buf_up.At(idx + 1) <= m_level_down_exit ||
       m_buf_down.At(idx + 1) <= m_level_down_exit)) {

    m_exit_direction = 1;
    m_state = SignalNoTrade;
    return true;
  }
  return false;
}

bool CBothLinesTwoLevelsCrossSignal::InitIndicatorBuffers() {
  m_buf_up = m_indicator.At(m_buffers[0]);
  m_buf_down = m_indicator.At(m_buffers[1]);
  m_level_up_enter = m_config[0];
  m_level_up_exit = m_config[1];
  m_level_down_enter = m_config[2];
  m_level_down_exit = m_config[3];
  return true;
}

bool CBothLinesTwoLevelsCrossSignal::UpdateStrictSide() {
  int idx = StartIndex();
  if (m_buf_up.At(idx) > m_level_up_enter &&
      m_buf_down.At(idx) > m_level_up_enter &&
      m_buf_up.At(idx) <= m_level_up_exit &&
      m_buf_down.At(idx) <= m_level_up_exit) {

    // only set the state not the m_sig_direction
    m_state = SignalLong;
    return true;

  } else if (m_buf_up.At(idx) <= m_level_down_enter &&
             m_buf_down.At(idx) <= m_level_down_enter &&
             m_buf_up.At(idx) > m_level_down_exit &&
             m_buf_down.At(idx) > m_level_down_exit) {

    m_state = SignalShort;
    return true;

  } else if (m_level_up_enter >= m_level_up_exit &&
             m_level_down_enter <= m_level_down_exit) {
    // The up/down Enter levels are clear and we can assign SignalNoTrade state
    // if the current value is between up_enter and down_enter
    if (m_buf_up.At(idx) <= m_level_up_enter &&
        m_buf_down.At(idx) <= m_level_up_enter &&
        m_buf_up.At(idx) > m_level_down_enter &&
        m_buf_down.At(idx) > m_level_down_enter) {

      m_state = SignalNoTrade;
      return true;
    }
    // else -> up_enter is lower than up_exit -> reversal indicator that is
    // leaving the overbought/oversold area I can't guarantee proper Both Line
    // crosses if I would set SignalNoTrade here
  }
  // no strict side could be found -> we're staying at Init state until the
  // situation is clear
  return false;
}

// if we are in long state and the line has returned fully below up_enter
// we may get another long signal which can be a continueation signal
bool CBothLinesTwoLevelsCrossSignal::UpdateLongReturn() {
  int idx = StartIndex();
  if (m_buf_up.At(idx) <= m_level_up_enter &&
      m_buf_down.At(idx) <= m_level_up_enter) {
    m_state = SignalLongReturn;
    return true;
  }
  return false;
}

bool CBothLinesTwoLevelsCrossSignal::UpdateShortReturn() {
  int idx = StartIndex();
  if (m_buf_up.At(idx) > m_level_down_enter &&
      m_buf_down.At(idx) > m_level_down_enter) {
    m_state = SignalShortReturn;
    return true;
  }
  return false;
}

bool CBothLinesTwoLevelsCrossSignal::Update() {
  m_sig_direction = 0;
  m_exit_direction = 0;
  switch (m_state) {
  case SignalInit:
    UpdateStrictSide();
    break;
  case SignalNoTrade:
    if (!UpdateLongSignal())
      UpdateShortSignal();
    break;
  case SignalLongReturn:
    UpdateLongSignal();  // possible continuation
  case SignalLong:
    UpdateLongReturn();  // needs to be evaluated first.
    UpdateLongExit();    // exit and short signal state changes have higher priority
    UpdateShortSignal();
    break;
  case SignalShortReturn:
    UpdateShortSignal();
  case SignalShort:
    UpdateShortReturn();
    UpdateShortExit();
    UpdateLongSignal();
    break;
  default:
    Alert("ERROR: unknown state found in SIGNAL_STATE");
    return false;
  }
  UpdateSide();
  return true;
}
