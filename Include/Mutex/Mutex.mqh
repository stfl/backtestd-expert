//+------------------------------------------------------------------+
//|                                                            Mutex |
//|                            Copyright © 2006-2013, FINEXWARE GmbH |
//|                                                www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2013, FINEXWARE GmbH"
#property link "www.FINEXWARE.com"
#property version "1.00"
#property library

#define HANDLE64 long
#define HANDLE32 int
#define BOOL int
#define LPCTSTR string
#define DWORD int
#define LPSECURITY_ATTRIBUTES64 long
#define LPSECURITY_ATTRIBUTES32 int

#define INFINITE 0xFFFFFFFF // Infinite timeout

#define STANDARD_RIGHTS_REQUIRED (0x000F0000)
#define SYNCHRONIZE (0x00100000)
#define MUTANT_QUERY_STATE 0x0001

#define MUTANT_ALL_ACCESS                                                      \
  (STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | MUTANT_QUERY_STATE)
#define MUTEX_ALL_ACCESS MUTANT_ALL_ACCESS

#define WAIT_ABANDONED 0x00000080
#define WAIT_OBJECT_0 0x00000000
#define WAIT_TIMEOUT 0x00000102
#define WAIT_FAILED (DWORD)0xFFFFFFFF

#import "kernel32.dll"
// 64
HANDLE64 CreateMutexW(LPSECURITY_ATTRIBUTES64 lpMutexAttributes,
                      BOOL bInitialOwner, LPCTSTR lpName);
BOOL ReleaseMutex(HANDLE64 hMutex);
BOOL CloseHandle(HANDLE64 hObject);
DWORD WaitForSingleObject(HANDLE64 hHandle, DWORD dwMilliseconds);

// 32
HANDLE32 CreateMutexW(LPSECURITY_ATTRIBUTES32 lpMutexAttributes,
                      BOOL bInitialOwner, LPCTSTR lpName);
BOOL ReleaseMutex(HANDLE32 hMutex);
BOOL CloseHandle(HANDLE32 hObject);
DWORD WaitForSingleObject(HANDLE32 hHandle, DWORD dwMilliseconds);
#import
HANDLE64 CreateMutexWX(LPSECURITY_ATTRIBUTES64 lpMutexAttributes,
                       BOOL bInitialOwner, LPCTSTR lpName) {
  if (_IsX64)
    return (CreateMutexW(lpMutexAttributes, bInitialOwner, lpName));
  return (CreateMutexW((LPSECURITY_ATTRIBUTES32)lpMutexAttributes,
                       bInitialOwner, lpName));
}
BOOL ReleaseMutexX(HANDLE64 hMutex) {
  if (_IsX64)
    return (ReleaseMutex(hMutex));
  return (ReleaseMutex((HANDLE32)hMutex));
}
BOOL CloseHandleX(HANDLE64 hObject) {
  if (_IsX64)
    return (CloseHandle(hObject));
  return (CloseHandle((HANDLE32)hObject));
}
DWORD WaitForSingleObjectX(HANDLE64 hHandle, DWORD dwMilliseconds) {
  if (_IsX64)
    return (WaitForSingleObject(hHandle, dwMilliseconds));
  return (WaitForSingleObject((HANDLE32)hHandle, dwMilliseconds));
}

//------------------------------------------------------------------	class
// CMutexSrc
class CMutexSync {
  HANDLE64 m_mutex;

public:
  CMutexSync() { m_mutex = NULL; }
  virtual ~CMutexSync() { Destroy(); }
  bool Create(LPCTSTR name) {
    m_mutex = CreateMutexWX(0, false, name);
    return (m_mutex != NULL);
  }
  void Destroy() {
    CloseHandleX(m_mutex);
    m_mutex = NULL;
  }
  HANDLE64 Get() const { return (m_mutex); }
};

//------------------------------------------------------------------	class
// CMutexLock
class CMutexLock {
  HANDLE64 m_mutex; // äåñêðèïòîð çàõâàòûâàåìîãî ìþòåêñà
  bool m_success;

public:
  CMutexLock(CMutexSync &m, DWORD dwWaitMsec) {
    m_mutex = m.Get();
    const DWORD res = WaitForSingleObjectX(m_mutex, dwWaitMsec);
  }
  ~CMutexLock() { ReleaseMutexX(m_mutex); }
  bool Success() { return m_success; }
};
