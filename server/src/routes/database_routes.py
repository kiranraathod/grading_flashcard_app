"""
Database testing routes for Task 2.2 validation.
Provides comprehensive endpoints for testing database connectivity, CRUD operations, and RLS policies.
"""
from fastapi import APIRouter, HTTPException, status
from typing import Dict, Any
import logging
from datetime import datetime

# Import database service
try:
    from ..services.database_service import db_service
except ImportError:
    # Fallback import for different module structures
    import sys
    import os
    sys.path.append(os.path.dirname(os.path.dirname(__file__)))
    from services.database_service import db_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/database", tags=["database"])

@router.get("/test-connection", 
            summary="Test Database Connection",
            description="Test basic connectivity to Supabase database and verify table accessibility")
async def test_database_connection() -> Dict[str, Any]:
    """Test database connectivity and return detailed status."""
    try:
        logger.info("🔧 Starting database connection test...")
        connection_result = await db_service.test_connection()
        
        # Determine response status based on results
        if connection_result.get('error'):
            logger.error(f"❌ Database connection test failed: {connection_result['error']}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
                detail={
                    "error": "Database connection failed",
                    "details": connection_result,
                    "timestamp": datetime.now().isoformat()
                }
            )
        
        # Check if connection is healthy
        is_healthy = (
            connection_result.get('supabase_connected', False) and
            connection_result.get('tables_accessible', False) and
            connection_result.get('performance_ok', False)
        )
        
        response_data = {
            "status": "success" if is_healthy else "degraded",
            "message": "Database connection test completed",
            "results": connection_result,
            "summary": {
                "connected": connection_result.get('supabase_connected', False),
                "tables_ok": connection_result.get('tables_accessible', False),
                "performance_ok": connection_result.get('performance_ok', False),
                "table_count": connection_result.get('accessible_table_count', 0),
                "response_time": connection_result.get('response_time_seconds', 'unknown')
            },
            "timestamp": datetime.now().isoformat()
        }
        
        if is_healthy:
            logger.info("✅ Database connection test completed successfully")
        else:
            logger.warning("⚠️ Database connection test completed with issues")
            
        return response_data
    
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"❌ Database connection test endpoint failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail={
                "error": "Internal server error during database test",
                "message": str(e),
                "timestamp": datetime.now().isoformat()
            }
        )

@router.get("/test-crud",
            summary="Test CRUD Operations", 
            description="Test Create, Read, Update, Delete operations on the database")
async def test_crud_operations() -> Dict[str, Any]:
    """Test CRUD operations on the database."""
    try:
        logger.info("🔧 Starting CRUD operations test...")
        crud_result = await db_service.test_crud_operations()
        
        # Check success rate
        all_operations_successful = all([
            crud_result.get('create_success', False),
            crud_result.get('read_success', False),
            crud_result.get('update_success', False),
            crud_result.get('delete_success', False)
        ])
        
        successful_count = sum([
            crud_result.get('create_success', False),
            crud_result.get('read_success', False),
            crud_result.get('update_success', False),
            crud_result.get('delete_success', False)
        ])
        
        # Log results
        if all_operations_successful:
            logger.info("✅ All CRUD operations successful")
        else:
            logger.warning(f"⚠️ CRUD operations partially successful: {successful_count}/4")
            if crud_result.get('error'):
                logger.error(f"CRUD error details: {crud_result['error']}")
        
        response_data = {
            "status": "success" if all_operations_successful else "partial",
            "message": "CRUD operations test completed",
            "results": crud_result,
            "summary": {
                "all_operations_successful": all_operations_successful,
                "successful_operations": successful_count,
                "total_operations": 4,
                "success_rate": crud_result.get('success_rate', 'unknown'),
                "test_record_id": crud_result.get('test_record_id')
            },
            "operations_log": crud_result.get('operations_log', []),
            "timestamp": datetime.now().isoformat()
        }
        
        return response_data
    
    except Exception as e:
        logger.error(f"❌ CRUD test endpoint failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail={
                "error": "Internal server error during CRUD test",
                "message": str(e),
                "timestamp": datetime.now().isoformat()
            }
        )

@router.get("/test-rls",
            summary="Test RLS Policies",
            description="Test Row Level Security policies to ensure proper data protection")
async def test_rls_policies() -> Dict[str, Any]:
    """Test Row Level Security policies."""
    try:
        logger.info("🔧 Starting RLS policies test...")
        rls_result = await db_service.test_rls_policies()
        
        is_rls_working = rls_result.get('rls_working', False)
        
        if is_rls_working:
            logger.info("✅ RLS policies working correctly")
        else:
            logger.warning("⚠️ RLS policies may need attention")
        
        response_data = {
            "status": "success",
            "message": "RLS policy test completed",
            "results": rls_result,
            "summary": {
                "rls_working": is_rls_working,
                "guest_access_ok": rls_result.get('guest_sessions_accessible', False),
                "auth_tables_protected": rls_result.get('auth_tables_protected', False),
                "security_level": "high" if is_rls_working else "needs_review"
            },
            "policy_details": rls_result.get('policy_tests', {}),
            "timestamp": datetime.now().isoformat()
        }
        
        return response_data
    
    except Exception as e:
        logger.error(f"❌ RLS test endpoint failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail={
                "error": "Internal server error during RLS test",
                "message": str(e),
                "timestamp": datetime.now().isoformat()
            }
        )

@router.get("/stats",
            summary="Get Database Statistics",
            description="Retrieve comprehensive database statistics and health metrics")
async def get_database_stats() -> Dict[str, Any]:
    """Get database statistics and health metrics."""
    try:
        logger.info("🔧 Collecting database statistics...")
        stats_result = await db_service.get_database_stats()
        
        if stats_result.get('error'):
            logger.warning(f"⚠️ Database stats collection had issues: {stats_result['error']}")
        else:
            logger.info("✅ Database statistics collected successfully")
        
        response_data = {
            "status": "success" if not stats_result.get('error') else "partial",
            "message": "Database stats retrieved",
            "stats": stats_result,
            "timestamp": datetime.now().isoformat()
        }
        
        return response_data
    
    except Exception as e:
        logger.error(f"❌ Database stats endpoint failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail={
                "error": "Internal server error during stats collection",
                "message": str(e),
                "timestamp": datetime.now().isoformat()
            }
        )

@router.get("/health",
            summary="Comprehensive Database Health Check",
            description="Run all database tests and provide overall health assessment")
async def database_health() -> Dict[str, Any]:
    """Comprehensive database health check."""
    try:
        logger.info("🔧 Starting comprehensive database health check...")
        
        # Run all tests
        connection_test = await db_service.test_connection()
        crud_test = await db_service.test_crud_operations()
        rls_test = await db_service.test_rls_policies()
        stats = await db_service.get_database_stats()
        
        # Calculate overall health score
        health_checks = {
            'connection_ok': connection_test.get('supabase_connected', False),
            'tables_accessible': connection_test.get('tables_accessible', False),
            'performance_ok': connection_test.get('performance_ok', False),
            'crud_create_ok': crud_test.get('create_success', False),
            'crud_read_ok': crud_test.get('read_success', False),
            'crud_update_ok': crud_test.get('update_success', False),
            'crud_delete_ok': crud_test.get('delete_success', False),
            'rls_working': rls_test.get('rls_working', False)
        }
        
        health_score = sum(health_checks.values())
        max_score = len(health_checks)
        health_percentage = (health_score / max_score) * 100
        
        # Determine overall health status
        if health_percentage >= 90:
            overall_status = "healthy"
        elif health_percentage >= 75:
            overall_status = "degraded"
        elif health_percentage >= 50:
            overall_status = "unhealthy"
        else:
            overall_status = "critical"
        
        # Check readiness for next phase
        ready_for_authentication = (
            health_percentage >= 85 and 
            rls_test.get('rls_working', False) and
            connection_test.get('tables_accessible', False)
        )
        
        response_data = {
            "status": overall_status,
            "health_score": f"{health_percentage:.1f}%",
            "health_details": health_checks,
            "details": {
                "connection": connection_test,
                "crud_operations": crud_test,
                "rls_policies": rls_test,
                "statistics": stats
            },
            "summary": {
                "database_operational": health_percentage >= 85,
                "ready_for_authentication": ready_for_authentication,
                "performance_acceptable": connection_test.get('performance_ok', False),
                "security_configured": rls_test.get('rls_working', False),
                "total_checks": max_score,
                "passed_checks": health_score
            },
            "recommendations": [],
            "timestamp": datetime.now().isoformat()
        }
        
        # Add recommendations based on results
        if not connection_test.get('supabase_connected', False):
            response_data["recommendations"].append("Check SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
        
        if not connection_test.get('performance_ok', False):
            response_data["recommendations"].append("Consider optimizing database connection or using connection pooling")
        
        if not rls_test.get('rls_working', False):
            response_data["recommendations"].append("Review and verify Row Level Security policies")
        
        if health_percentage < 85:
            response_data["recommendations"].append("Address failing health checks before proceeding to authentication system")
        
        if not response_data["recommendations"]:
            response_data["recommendations"].append("Database is healthy and ready for production use")
        
        # Log overall result
        logger.info(f"✅ Database health check completed: {overall_status} ({health_percentage:.1f}%)")
        if ready_for_authentication:
            logger.info("✅ Database ready for authentication system activation")
        else:
            logger.warning("⚠️ Database not ready for authentication system - address issues first")
        
        return response_data
    
    except Exception as e:
        logger.error(f"❌ Database health check failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail={
                "error": "Internal server error during health check",
                "message": str(e),
                "timestamp": datetime.now().isoformat()
            }
        )

@router.get("/ping",
            summary="Simple Database Ping",
            description="Quick connectivity check for monitoring")
async def database_ping() -> Dict[str, Any]:
    """Simple database ping for basic connectivity check."""
    try:
        if not db_service.supabase:
            return {
                "status": "error",
                "message": "Database client not initialized",
                "timestamp": datetime.now().isoformat()
            }
        
        # Simple ping test
        start_time = datetime.now()
        response = db_service.supabase.table('guest_sessions').select('count', count='exact').execute()
        end_time = datetime.now()
        
        response_time = (end_time - start_time).total_seconds()
        
        return {
            "status": "ok",
            "message": "Database responding",
            "response_time_ms": round(response_time * 1000, 2),
            "timestamp": datetime.now().isoformat()
        }
    
    except Exception as e:
        logger.error(f"❌ Database ping failed: {e}")
        return {
            "status": "error", 
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }
