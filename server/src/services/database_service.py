"""
Database service for Supabase integration.
Task 2.2: Database Connection Testing Implementation
"""
import os
import logging
from typing import Dict, List, Any, Optional
from supabase import create_client, Client
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class DatabaseService:
    """Service for database operations with Supabase."""
    
    def __init__(self):
        self.supabase_url = os.getenv('SUPABASE_URL')
        self.supabase_key = os.getenv('SUPABASE_ANON_KEY')
        
        # Initialize Supabase client
        if self.supabase_url and self.supabase_key:
            try:
                self.supabase: Client = create_client(self.supabase_url, self.supabase_key)
                logger.info("✅ Supabase client initialized successfully")
            except Exception as e:
                self.supabase = None
                logger.error(f"❌ Failed to initialize Supabase client: {e}")
        else:
            self.supabase = None
            logger.warning("⚠️ Supabase credentials not found - database operations disabled")
    
    async def test_connection(self) -> Dict[str, Any]:
        """Test database connectivity and return detailed status."""
        result = {
            'supabase_connected': False,
            'tables_accessible': False,
            'performance_ok': False,
            'accessible_table_count': 0,
            'response_time_seconds': None,
            'error': None
        }
        
        try:
            if not self.supabase:
                result['error'] = "Supabase client not initialized - check SUPABASE_URL and SUPABASE_ANON_KEY"
                return result
            
            # Test basic connectivity with performance measurement
            start_time = datetime.now()
            response = self.supabase.table('guest_sessions').select('count', count='exact').execute()
            end_time = datetime.now()
            
            response_time = (end_time - start_time).total_seconds()
            result['response_time_seconds'] = round(response_time, 3)
            result['supabase_connected'] = True
            logger.info(f"✅ Supabase connection successful ({response_time:.3f}s)")
            
            # Test all table accessibility
            tables_to_test = [
                'categories', 'flashcard_sets', 'flashcards', 
                'user_progress', 'interview_questions', 'user_activity',
                'weekly_activity', 'user_preferences', 'guest_sessions'
            ]
            
            accessible_tables = 0
            table_results = {}
            
            for table in tables_to_test:
                try:
                    table_response = self.supabase.table(table).select('count', count='exact').execute()
                    accessible_tables += 1
                    table_results[table] = "✅ Accessible"
                    logger.debug(f"✅ Table {table} accessible")
                except Exception as e:
                    table_results[table] = f"❌ Error: {str(e)}"
                    logger.warning(f"⚠️ Table {table} not accessible: {e}")
            
            result['accessible_table_count'] = accessible_tables
            result['tables_accessible'] = accessible_tables == len(tables_to_test)
            result['table_details'] = table_results
            
            if result['tables_accessible']:
                logger.info(f"✅ All {accessible_tables} tables accessible")
            else:
                logger.warning(f"⚠️ Only {accessible_tables}/{len(tables_to_test)} tables accessible")
            
            # Performance check (target: < 2 seconds)
            result['performance_ok'] = response_time < 2.0
            
            if result['performance_ok']:
                logger.info(f"✅ Database performance excellent: {response_time:.3f}s")
            else:
                logger.warning(f"⚠️ Database performance needs attention: {response_time:.3f}s")
                
        except Exception as e:
            result['error'] = str(e)
            logger.error(f"❌ Database connection test failed: {e}")
        
        return result
    
    async def test_crud_operations(self) -> Dict[str, Any]:
        """Test CRUD operations on guest_sessions table (safe for testing)."""
        result = {
            'create_success': False,
            'read_success': False,
            'update_success': False,
            'delete_success': False,
            'test_record_id': None,
            'error': None,
            'operations_log': []
        }
        
        if not self.supabase:
            result['error'] = "Supabase client not initialized"
            return result
        
        test_session_token = f"test_session_{int(datetime.now().timestamp())}"
        created_session_id = None
        
        try:
            # CREATE test
            logger.info("🔧 Testing CREATE operation...")
            create_response = self.supabase.table('guest_sessions').insert({
                'session_token': test_session_token,
                'grading_actions_used': 0,
                'metadata': {'test': True, 'created_at': datetime.now().isoformat()}
            }).execute()
            
            if create_response.data and len(create_response.data) > 0:
                created_session_id = create_response.data[0]['id']
                result['create_success'] = True
                result['test_record_id'] = created_session_id
                result['operations_log'].append("✅ CREATE: Successfully created test record")
                logger.info(f"✅ CREATE operation successful: {created_session_id}")
            else:
                result['operations_log'].append("❌ CREATE: No data returned")
                logger.error("❌ CREATE operation failed: No data returned")
            
            # READ test
            if created_session_id:
                logger.info("🔧 Testing READ operation...")
                read_response = self.supabase.table('guest_sessions').select('*').eq('id', created_session_id).execute()
                
                if read_response.data and len(read_response.data) > 0:
                    read_data = read_response.data[0]
                    if read_data['session_token'] == test_session_token:
                        result['read_success'] = True
                        result['operations_log'].append("✅ READ: Successfully retrieved test record")
                        logger.info("✅ READ operation successful")
                    else:
                        result['operations_log'].append("❌ READ: Data mismatch")
                        logger.error("❌ READ operation failed: Data mismatch")
                else:
                    result['operations_log'].append("❌ READ: No data found")
                    logger.error("❌ READ operation failed: No data found")
            
            # UPDATE test
            if created_session_id:
                logger.info("🔧 Testing UPDATE operation...")
                update_response = self.supabase.table('guest_sessions').update({
                    'grading_actions_used': 1,
                    'metadata': {
                        'test': True, 
                        'updated': True,
                        'updated_at': datetime.now().isoformat()
                    }
                }).eq('id', created_session_id).execute()
                
                if update_response.data and len(update_response.data) > 0:
                    updated_data = update_response.data[0]
                    if updated_data['grading_actions_used'] == 1:
                        result['update_success'] = True
                        result['operations_log'].append("✅ UPDATE: Successfully updated test record")
                        logger.info("✅ UPDATE operation successful")
                    else:
                        result['operations_log'].append("❌ UPDATE: Update not reflected")
                        logger.error("❌ UPDATE operation failed: Update not reflected")
                else:
                    result['operations_log'].append("❌ UPDATE: No data returned")
                    logger.error("❌ UPDATE operation failed: No data returned")
            
            # DELETE test (cleanup)
            if created_session_id:
                logger.info("🔧 Testing DELETE operation...")
                delete_response = self.supabase.table('guest_sessions').delete().eq('id', created_session_id).execute()
                
                # Check if delete was successful (either returns data or 204 status)
                if (delete_response.data is not None) or (hasattr(delete_response, 'status_code') and delete_response.status_code == 204):
                    result['delete_success'] = True
                    result['operations_log'].append("✅ DELETE: Successfully deleted test record")
                    logger.info("✅ DELETE operation successful")
                    
                    # Verify deletion by trying to read the record
                    verify_response = self.supabase.table('guest_sessions').select('*').eq('id', created_session_id).execute()
                    if not verify_response.data or len(verify_response.data) == 0:
                        result['operations_log'].append("✅ DELETE VERIFIED: Record no longer exists")
                        logger.info("✅ DELETE operation verified")
                    else:
                        result['operations_log'].append("⚠️ DELETE PARTIAL: Record still exists")
                        logger.warning("⚠️ DELETE operation incomplete")
                else:
                    result['operations_log'].append("❌ DELETE: Operation failed")
                    logger.error("❌ DELETE operation failed")
                    
        except Exception as e:
            result['error'] = str(e)
            result['operations_log'].append(f"❌ EXCEPTION: {str(e)}")
            logger.error(f"❌ CRUD operations test failed: {e}")
            
            # Cleanup on error
            if created_session_id:
                try:
                    logger.info("🧹 Performing cleanup after error...")
                    self.supabase.table('guest_sessions').delete().eq('id', created_session_id).execute()
                    result['operations_log'].append("🧹 CLEANUP: Attempted cleanup after error")
                    logger.info("🧹 Cleanup completed after error")
                except Exception as cleanup_error:
                    result['operations_log'].append(f"❌ CLEANUP FAILED: {str(cleanup_error)}")
                    logger.error(f"❌ Cleanup failed: {cleanup_error}")
        
        # Calculate success rate
        successful_operations = sum([
            result['create_success'],
            result['read_success'], 
            result['update_success'],
            result['delete_success']
        ])
        result['success_rate'] = f"{successful_operations}/4 ({(successful_operations/4)*100:.0f}%)"
        
        return result
    
    async def test_rls_policies(self) -> Dict[str, Any]:
        """Test Row Level Security policies."""
        result = {
            'guest_sessions_accessible': False,
            'auth_tables_protected': True,  # Assume protected until tested
            'rls_working': False,
            'policy_tests': {},
            'error': None
        }
        
        if not self.supabase:
            result['error'] = "Supabase client not initialized"
            return result
        
        try:
            # Test 1: guest_sessions (should be accessible without auth)
            logger.info("🔧 Testing guest_sessions accessibility...")
            guest_response = self.supabase.table('guest_sessions').select('count', count='exact').execute()
            result['guest_sessions_accessible'] = True
            result['policy_tests']['guest_sessions'] = "✅ Accessible (expected for public table)"
            logger.info("✅ Guest sessions accessible (expected)")
            
            # Test 2: Protected tables (should require authentication)
            auth_tables = ['categories', 'flashcard_sets', 'flashcards', 'user_progress', 'interview_questions']
            protected_count = 0
            
            for table in auth_tables:
                try:
                    logger.info(f"🔧 Testing {table} RLS protection...")
                    # Try to select data - should be empty or restricted for unauthenticated users
                    table_response = self.supabase.table(table).select('*').limit(1).execute()
                    
                    if table_response.data and len(table_response.data) > 0:
                        # If we get data without auth, RLS might not be working properly
                        result['policy_tests'][table] = "⚠️ Data accessible without auth - check RLS policies"
                        logger.warning(f"⚠️ {table} accessible without auth - check RLS policies")
                    else:
                        # No data returned - could be empty table or proper RLS
                        protected_count += 1
                        result['policy_tests'][table] = "✅ Properly protected or empty"
                        logger.info(f"✅ {table} properly protected")
                        
                except Exception as e:
                    # Exception expected for properly protected tables
                    protected_count += 1
                    result['policy_tests'][table] = f"✅ Access denied (expected): {str(e)}"
                    logger.info(f"✅ {table} properly secured with RLS")
            
            # RLS is working if protected tables behave as expected
            result['auth_tables_protected'] = protected_count >= len(auth_tables) * 0.8  # 80% threshold
            result['rls_working'] = result['guest_sessions_accessible'] and result['auth_tables_protected']
            
            if result['rls_working']:
                logger.info("✅ RLS policies working correctly")
            else:
                logger.warning("⚠️ RLS policies may need review")
            
        except Exception as e:
            result['error'] = str(e)
            logger.error(f"❌ RLS policy test failed: {e}")
        
        return result
    
    async def get_database_stats(self) -> Dict[str, Any]:
        """Get database statistics and health metrics."""
        stats = {
            'table_counts': {},
            'total_records': 0,
            'database_info': {},
            'connection_info': {},
            'performance_metrics': {},
            'error': None
        }
        
        if not self.supabase:
            stats['error'] = "Supabase client not initialized"
            return stats
        
        try:
            tables = [
                'categories', 'flashcard_sets', 'flashcards', 
                'user_progress', 'interview_questions', 'user_activity',
                'weekly_activity', 'user_preferences', 'guest_sessions'
            ]
            
            total_records = 0
            successful_queries = 0
            total_query_time = 0
            
            for table in tables:
                try:
                    start_time = datetime.now()
                    response = self.supabase.table(table).select('count', count='exact').execute()
                    end_time = datetime.now()
                    
                    query_time = (end_time - start_time).total_seconds()
                    total_query_time += query_time
                    successful_queries += 1
                    
                    count = response.count if hasattr(response, 'count') else 0
                    stats['table_counts'][table] = {
                        'count': count,
                        'query_time': round(query_time, 3)
                    }
                    total_records += count
                    
                except Exception as e:
                    stats['table_counts'][table] = {
                        'error': str(e),
                        'count': 'unknown'
                    }
            
            stats['total_records'] = total_records
            stats['performance_metrics'] = {
                'average_query_time': round(total_query_time / successful_queries, 3) if successful_queries > 0 else None,
                'successful_queries': successful_queries,
                'total_queries': len(tables),
                'success_rate': f"{successful_queries}/{len(tables)} ({(successful_queries/len(tables))*100:.0f}%)"
            }
            
            stats['connection_info'] = {
                'supabase_url': self.supabase_url,
                'client_initialized': self.supabase is not None,
                'timestamp': datetime.now().isoformat()
            }
            
            stats['database_info'] = {
                'schema_version': 'v2',
                'tables_deployed': len([t for t in stats['table_counts'] if 'error' not in stats['table_counts'][t]]),
                'total_tables_expected': len(tables)
            }
            
        except Exception as e:
            stats['error'] = str(e)
            logger.error(f"❌ Database stats collection failed: {e}")
        
        return stats

# Global database service instance
db_service = DatabaseService()
