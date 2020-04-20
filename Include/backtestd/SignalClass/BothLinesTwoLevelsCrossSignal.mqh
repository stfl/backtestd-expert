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
  bool m_stateful_side; // Side considers the enter or the exit values
  int m_last_signal;

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
  virtual bool LongSide(void);
  virtual bool ShortSide(void);
  virtual bool LongSignal(void);
  virtual bool ShortSignal(void);
  virtual bool LongExit(void);
  virtual bool ShortExit(void);

  CBothLinesTwoLevelsCrossSignal(void);

protected:
  virtual bool InitIndicatorBuffers();
};

CBothLinesTwoLevelsCrossSignal::CBothLinesTwoLevelsCrossSignal(void) {
  m_stateful_side = false;
  m_last_signal = 0;
}

bool CBothLinesTwoLevelsCrossSignal::LongSide(void) {
  int idx = StartIndex();
  if (m_stateful_side) {
    LongSignal(); // calculate Signal in case we don't have m_last_signal set
    // yet.
    return m_last_signal > 0; // consider the last signal
  } else {
    if (m_buf_up.At(idx) > m_level_up_enter &&
        m_buf_down.At(idx) > m_level_up_enter) {
      // if both lines are on the up side, there has been a signal at some point
      // we need to set this here in order to ensure a first initialization of
      // m_last_signal
      // m_last_signal = 100;
      return true;
    } else
      return false;
  }
}

bool CBothLinesTwoLevelsCrossSignal::ShortSide(void) {
  int idx = StartIndex();
  if (m_stateful_side) {
    ShortSignal(); // calculate Signal in case we don't have m_last_signal set
    // yet.
    return m_last_signal < 0; // consider the last signal
  } else {
    if (m_buf_down.At(idx) < m_level_down_enter &&
        m_buf_up.At(idx) < m_level_down_enter) {
      // m_last_signal = -100;
      return true;
    } else
      return false;
  }
}

bool CBothLinesTwoLevelsCrossSignal::LongSignal(void) {
  int idx = StartIndex();
  bool signal = false;
  bool crossed = ((m_buf_up.At(idx) > m_level_up_enter &&
                   m_buf_down.At(idx) > m_level_up_enter) &&
                  (m_buf_up.At(idx + 1) <= m_level_up_enter ||
                   m_buf_down.At(idx + 1) <= m_level_up_enter));

  if (crossed) {
     for (int i=1; 128; t++) {    // we got back on the signal lines
        // we are checking if both lines crossed down before crossing back up now

        // if we find them to be both up before they where both down
        // they didn't actually full cross down before
        // this means only a single line has crossed down and back up and we can ignore this cross
        if ((m_buf_up.At(idx + i) > m_level_up_enter &&
             m_buf_down.At(idx + i) > m_level_up_enter)) {
           signal = false;
           break;
        }

        if ((m_buf_up.At(idx + i) <= m_level_up_enter &&
             m_buf_down.At(idx + i) <= m_level_up_enter)) {
           signal = true;
           break;
        }
     }
  }

  if (signal)
    m_last_signal = 100;
  return signal;
}

bool CBothLinesTwoLevelsCrossSignal::ShortSignal(void) {
  int idx = StartIndex();
  bool signal =
      m_last_signal > 0 && ((m_buf_up.At(idx) <= m_level_down_enter &&
                             m_buf_down.At(idx) <= m_level_down_enter) &&
                            (m_buf_up.At(idx + 1) > m_level_down_enter ||
                             m_buf_down.At(idx + 1) > m_level_down_enter));

  if (crossed) {
     for (int i=1; 128; t++) {    // we got back on the signal lines
        // we are checking if both lines crossed down before crossing back up now          // if we find them to be both up before they where both down
        // they didn't actually full cross down before
        // this means only a single line has crossed down and back up and we can ignore this cross
    }

        if ((m_buf_up.At(idx + i) > _up_l_down_enter &&
             m_buf_down.At(idx + i) > _up_l_down_enter)) {
           sifalse = true;
           break;
            if ((m_buf_up.At(idx + i) <= m_level_up_enter &&
             m_buf_down.At(idx + i) <= m_level_up_enter)) {
           signal = true;
           break;
        }
    }
  }


  if (signal)
    m_last_signal = -100;
  return signal;
}

bool CBothLinesTwoLevelsCrossSignal::LongExit(void) {
  int idx = StartIndex();
  return (ShortSignal() || (m_last_signal > 0 &&
                            (m_buf_up.At(idx) <= m_level_up_exit &&
                             m_buf_down.At(idx) <= m_level_up_exit) &&
                            (m_buf_up.At(idx + 1) > m_level_up_exit ||
                             m_buf_down.At(idx + 1) > m_level_up_exit)));
}

bool CBothLinesTwoLevelsCrossSignal::ShortExit(void) {
  int idx = StartIndex();
  return (LongSignal() || (m_last_signal < 0 &&
                           (m_buf_up.At(idx) > m_level_down_exit &&
                            m_buf_down.At(idx) > m_level_down_exit) &&
                           (m_buf_up.At(idx + 1) <= m_level_down_exit ||
                            m_buf_down.At(idx + 1) <= m_level_down_exit)));
}

bool CBothLinesTwoLevelsCrossSignal::InitIndicatorBuffers() {
  m_buf_up = m_indicator.At(m_buffers[0]);
  m_buf_down = m_indicator.At(m_buffers[1]);
  m_level_up_enter = m_config[0];
  m_level_up_exit = m_config[1];
  m_level_down_enter = m_config[2];
  m_level_down_exit = m_config[3];
  m_stateful_side = m_config[4];
  return true;
}
