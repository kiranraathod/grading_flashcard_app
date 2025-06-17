# FlashMaster Documentation Index

**Last Updated**: June 16, 2025  
**Current System**: Unified Storage Architecture v3.0  

---

## 📚 **Current Documentation** (June 2025)

### **🟢 Active & Current**
- **[Unified System Integration Guide](unified_system_supabase_integration_2025-06-16.md)** ⭐
  - **Status**: Current & Complete
  - **Purpose**: Comprehensive guide for unified system + Supabase
  - **Use For**: Implementation, troubleshooting, architecture reference

- **[Quick Reference](QUICK_REFERENCE_2025-06-16.md)** ⭐
  - **Status**: Current 
  - **Purpose**: Fast lookup for provider names, patterns, debug commands
  - **Use For**: Daily development, quick answers

### **🟡 Legacy Documentation** (For Historical Reference)
- `complete_implementation_summary.md` - Overview of v1 vs v2 (outdated provider names)
- `unified_storage_migration_guide.md` - Migration guide (mostly current)
- `supabase_integration_guide.md` - Original integration plan (comprehensive but outdated)
- `v2_testing_guide.md` - Testing procedures (needs provider name updates)

---

## 🎯 **What to Use When**

### **For Implementation**
1. **Start Here**: [Quick Reference](QUICK_REFERENCE_2025-06-16.md) - Get provider names and patterns
2. **Deep Dive**: [Unified System Integration Guide](unified_system_supabase_integration_2025-06-16.md) - Complete implementation

### **For Database Setup**
- **Schema**: `database_schema/2025-06-10_supabase_schema_v2.sql`
- **Guide**: Section 🗄️ in [Unified System Integration Guide](unified_system_supabase_integration_2025-06-16.md)

### **For Troubleshooting**
- **Debug Commands**: [Quick Reference](QUICK_REFERENCE_2025-06-16.md) - Common Issues section
- **Detailed Troubleshooting**: [Unified System Integration Guide](unified_system_supabase_integration_2025-06-16.md) - 🚨 section

---

## 🔄 **Migration from Legacy Docs**

If you're following older documentation, update these references:

| Old Reference | New Reference |
|---------------|---------------|
| `GuestUserManager` | Built into `UnifiedActionTracker` |
| `actionTrackerProvider` | `unifiedActionTrackerProvider` |
| `usageLimitEnforcerProvider` | `unifiedUsageLimitEnforcerProvider` |
| Individual action limits | Combined quota system (3/5 total) |

---

## 📋 **Documentation Status**

| Document | Status | Last Update | Next Review |
|----------|--------|-------------|-------------|
| Unified System Integration Guide | ✅ Current | 2025-06-16 | 2025-07-16 |
| Quick Reference | ✅ Current | 2025-06-16 | 2025-07-16 |
| Database Schema v2 | ✅ Current | 2025-06-10 | As needed |
| Legacy migration guide | ⚠️ Partially outdated | Various | 2025-07-01 |
| Testing guide | ⚠️ Needs provider updates | Various | 2025-07-01 |

---

## 🚀 **Quick Start for New Developers**

1. **Read**: [Quick Reference](QUICK_REFERENCE_2025-06-16.md) (5 minutes)
2. **Implement**: Use the provider patterns and examples
3. **Deep Dive**: [Unified System Integration Guide](unified_system_supabase_integration_2025-06-16.md) when needed
4. **Database**: Deploy `database_schema/2025-06-10_supabase_schema_v2.sql` for Supabase

---

## 📞 **Support**

- **Architecture Questions**: Reference [Unified System Integration Guide](unified_system_supabase_integration_2025-06-16.md)
- **Quick Answers**: Check [Quick Reference](QUICK_REFERENCE_2025-06-16.md)
- **Implementation Issues**: Use troubleshooting sections in current docs

---

**Maintained By**: FlashMaster Development Team  
**Documentation Version**: 3.0  
**System Version**: Unified Storage Architecture v3.0