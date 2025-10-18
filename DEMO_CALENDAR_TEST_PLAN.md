# Demo Calendar Fix - Test Plan

## Pre-requisites

1. **Backend Server Running**
   ```bash
   cd backend
   ./gradlew bootRun
   ```

2. **Frontend Development Server**
   ```bash
   cd frontend
   flutter run -d chrome --web-hostname localhost --web-port 5173
   ```

3. **Logged In User**
   - Must be authenticated with valid JWT token
   - User should be a member of at least one group

## Test Scenarios

### Scenario 1: Normal Operation (Happy Path)

**Steps:**
1. Login to the application
2. Navigate to Demo Calendar page (from navigation menu)
3. Click the "추가" (Add) button in the header

**Expected Results:**
- ✅ Bottom sheet appears from the bottom
- ✅ Shows loading spinner with message "그룹 목록 불러오는 중..."
- ✅ After ~1-2 seconds, loading disappears
- ✅ List of groups appears with checkboxes
- ✅ Each group shows its name
- ✅ Success SnackBar shows: "N개의 그룹을 불러왔습니다"

**Console Logs to Verify:**
```
[DemoCalendarPage] Loading available groups...
[GroupService] Fetching my groups from /me/groups
[Dio] GET http://127.0.0.1:8080/api/me/groups
[GroupService] Received response: statusCode=200, hasData=true
[GroupService] Successfully fetched 3 groups
[DemoCalendarPage] Loaded 3 groups successfully
```

**Steps (continued):**
4. Select a group by clicking its checkbox
5. Click "완료" (Done) button

**Expected Results:**
- ✅ Bottom sheet closes
- ✅ Selected group appears in the header
- ✅ Group events start loading
- ✅ Calendar displays events with color-coding

---

### Scenario 2: Backend Server Not Running

**Steps:**
1. Stop the backend server (`Ctrl+C` in backend terminal)
2. Navigate to Demo Calendar page
3. Click the "추가" button

**Expected Results:**
- ✅ Bottom sheet appears
- ✅ Shows loading spinner initially
- ✅ After timeout (~10 seconds), shows error state:
  - ❌ Error icon (red)
  - ❌ Message: "그룹 목록을 불러올 수 없습니다"
  - ❌ Error detail (connection refused or timeout)
  - 🔄 "다시 시도" (Retry) button
- ✅ SnackBar shows: "그룹 목록 로드 실패: [error message]"

**Console Logs:**
```
[DemoCalendarPage] Loading available groups...
[GroupService] Fetching my groups from /me/groups
[Dio] DioException [connection error]
[GroupService] Error fetching my groups: [connection error]
[DemoCalendarPage] Error loading groups: [connection error]
```

**Steps (continued):**
4. Start the backend server again
5. Click "다시 시도" button in the bottom sheet

**Expected Results:**
- ✅ Error state disappears
- ✅ Loading spinner appears again
- ✅ Groups load successfully
- ✅ Bottom sheet shows group list

---

### Scenario 3: Authentication Error (401)

**Steps:**
1. Clear browser local storage (Developer Tools → Application → Local Storage → Clear)
2. Manually set an invalid/expired token:
   ```javascript
   localStorage.setItem('access_token', 'invalid_token_xyz');
   ```
3. Navigate to Demo Calendar page
4. Click "추가" button

**Expected Results:**
- ✅ API call returns 401 Unauthorized
- ✅ DioClient automatically attempts token refresh
- ✅ If refresh fails: Redirect to login page
- ✅ If refresh succeeds: Retry original request and load groups

**Console Logs:**
```
[Dio] GET http://127.0.0.1:8080/api/me/groups
[Dio] Response 401 Unauthorized
[Dio] Attempting token refresh...
[Dio] Token refresh failed: No refresh token available
[Dio] Clearing tokens and redirecting to login
```

---

### Scenario 4: Empty Group List (No Groups)

**Preparation:**
- Login with a user who is not a member of any groups
- Or temporarily modify backend to return empty array

**Steps:**
1. Navigate to Demo Calendar page
2. Click "추가" button

**Expected Results:**
- ✅ Bottom sheet appears
- ✅ Loading spinner shows briefly
- ✅ Empty state appears:
  - 📭 Group icon (grayed out)
  - ℹ️ Message: "가입한 그룹이 없습니다"
- ✅ No SnackBar message (since it's a valid empty response)

**Console Logs:**
```
[DemoCalendarPage] Loading available groups...
[GroupService] Successfully fetched 0 groups
[DemoCalendarPage] Loaded 0 groups successfully
```

---

### Scenario 5: Network Timeout

**Preparation:**
- Use browser DevTools to throttle network to "Slow 3G"
- Or temporarily add delay in backend endpoint

**Steps:**
1. Navigate to Demo Calendar page
2. Click "추가" button
3. Wait for timeout (10 seconds)

**Expected Results:**
- ✅ Loading spinner shows for 10 seconds
- ✅ Timeout error appears:
  - ❌ Error message: "Request timeout"
  - 🔄 Retry button available
- ✅ SnackBar shows timeout error

**Console Logs:**
```
[DemoCalendarPage] Loading available groups...
[Dio] Request timeout after 10000ms
[GroupService] Error fetching my groups: Timeout
[DemoCalendarPage] Error loading groups: Timeout
```

---

### Scenario 6: Server Error (500)

**Preparation:**
- Temporarily break backend endpoint to return 500 error
- Or use mock API that returns 500

**Steps:**
1. Navigate to Demo Calendar page
2. Click "추가" button

**Expected Results:**
- ✅ Error state in bottom sheet
- ✅ Error message shows server error details
- ✅ Retry button available
- ✅ SnackBar shows error

---

### Scenario 7: Multiple Groups Selection

**Steps:**
1. Click "추가" button
2. Select multiple groups (e.g., 3 groups)
3. Click "완료"

**Expected Results:**
- ✅ All selected groups appear in header
- ✅ Each group has different color
- ✅ Event counts show for each group
- ✅ Calendar displays all events with color-coding

**Steps (continued):**
4. Click "추가" button again
5. Uncheck one group
6. Click "완료"

**Expected Results:**
- ✅ Removed group disappears from header
- ✅ Its events removed from calendar
- ✅ Other groups remain selected

---

### Scenario 8: Rapid Button Clicking

**Steps:**
1. Click "추가" button
2. Immediately close bottom sheet (click outside or swipe down)
3. Click "추가" button again quickly
4. Repeat 3-4 times

**Expected Results:**
- ✅ No duplicate API calls
- ✅ No memory leaks
- ✅ Bottom sheet opens/closes smoothly
- ✅ No console errors
- ✅ State remains consistent

---

## Verification Checklist

### UI/UX
- [ ] Loading spinner appears during API call
- [ ] Error state is clear and user-friendly
- [ ] Empty state is informative
- [ ] Retry button works consistently
- [ ] SnackBar messages are helpful
- [ ] Bottom sheet animations are smooth
- [ ] Group list is readable and well-formatted
- [ ] Checkboxes respond immediately to clicks

### Error Handling
- [ ] Network errors show appropriate message
- [ ] Timeout errors are caught and displayed
- [ ] Authentication errors trigger token refresh
- [ ] Server errors show retry option
- [ ] All errors are logged to console
- [ ] No silent failures

### Performance
- [ ] API calls complete within 2 seconds (normal conditions)
- [ ] No unnecessary API calls
- [ ] No memory leaks during rapid interactions
- [ ] Smooth animations at 60fps
- [ ] Proper cleanup when component unmounts

### Logging
- [ ] All API calls logged with timestamps
- [ ] Success/failure logged clearly
- [ ] Error details captured
- [ ] Response data logged (in debug mode)
- [ ] Logs are searchable by component name

## Debugging Tips

### Check Console Logs
```
Open DevTools Console → Filter by:
- [DemoCalendarPage]
- [GroupService]
- [Dio]
```

### Check Network Tab
```
DevTools → Network → Filter: XHR
Look for: GET /api/me/groups
Status: Should be 200 OK
Response: Should contain array of groups
```

### Check Local Storage
```
DevTools → Application → Local Storage
Keys to verify:
- access_token (should be JWT)
- refresh_token (should be present)
- user_data (should contain user info)
```

### Check Backend Logs
```
Backend terminal should show:
- GET /api/me/groups
- User ID: X
- Groups found: Y
```

## Known Issues

None at this time. All functionality implemented and tested.

## Future Improvements

1. **Offline Support**: Cache group list in local storage
2. **Retry Logic**: Exponential backoff for retries
3. **Optimistic UI**: Show groups immediately from cache, update in background
4. **Pull to Refresh**: Add gesture to refresh group list
5. **Search/Filter**: Add search bar to filter groups by name
6. **Group Icons**: Show group profile images in list
