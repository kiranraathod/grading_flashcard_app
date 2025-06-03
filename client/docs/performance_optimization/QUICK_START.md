# ⚡ Quick Reference - 20/80 Performance Optimization

## **4 Critical Tasks = 90% Performance Gain in 9 Hours**

### **🎯 Implementation Order:**

**Day 1:**
1. **Loading Screen** (2h) → 80% perceived improvement
2. **Network Timeouts** (1h) → 4x faster responses
3. **Start Const Widgets** (1h)

**Day 2:**
4. **Finish Const Widgets** (2h) → 40% fewer rebuilds  
5. **ListView.builder** (3h) → 70% memory reduction

### **📁 Files to Modify:**

**Task 1:** `client/web/index.html`
**Task 2:** `client/lib/utils/config.dart` (lines 19-23)
**Task 3:** Search/replace across `lib/widgets/` and `lib/screens/`
**Task 4:** Find ListView usage in flashcard/question lists

### **✅ Success Metrics:**
- No blank white screen
- 15s API timeouts (was 60s)
- Smooth UI interactions
- Smooth list scrolling
- Lighthouse score >80

### **🚫 Skip Until After Supabase:**
- Image optimization
- Complex caching  
- Build optimization
- Advanced features

**Result**: Production-ready performance in 2 days before Supabase implementation.

See `README.md` for detailed step-by-step instructions.