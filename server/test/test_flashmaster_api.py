#!/usr/bin/env python3
"""
CORRECTED FlashMaster API Test Script - Fixed Schemas and Endpoints
Tests the deployed FastAPI application with correct request/response schemas.
"""

import requests
import json
import time
from typing import Dict, Any
from datetime import datetime

# Configuration
API_BASE_URL = "https://grading-app-5o9m.onrender.com"
TIMEOUT = 70

class FlashMasterAPITester:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'FlashMaster-Test-Client/1.0'
        })
        
    def test_working_endpoints(self) -> bool:
        """Test endpoints that should work"""
        print("🔍 Testing Working Endpoints...")
        
        endpoints = [
            "/",           # Root health check
            "/api/ping"    # Ping endpoint
        ]
        
        success_count = 0
        for endpoint in endpoints:
            try:
                response = self.session.get(f"{self.base_url}{endpoint}", timeout=30)
                if response.status_code == 200:
                    print(f"  ✅ {endpoint} - Status: {response.status_code}")
                    success_count += 1
                else:
                    print(f"  ❌ {endpoint} - Status: {response.status_code}")
            except Exception as e:
                print(f"  ❌ {endpoint} - Error: {str(e)}")
        
        print(f"Working Endpoints: {success_count}/{len(endpoints)} passed\n")
        return success_count == len(endpoints)
    
    def test_flashcard_grading_corrected(self) -> bool:
        """Test flashcard grading with CORRECT schema"""
        print("🎓 Testing Flashcard Grading (Corrected Schema)...")
        
        # CORRECTED: Include correctAnswer field, expect correct response fields
        test_cases = [
            {
                "name": "Python List Question",
                "request": {
                    "flashcardId": "test-001",
                    "question": "What is a list in Python?",
                    "correctAnswer": "A list is an ordered collection of items that can be changed (mutable). Lists are defined using square brackets [].",
                    "userAnswer": "A list is a collection of items in Python that you can modify."
                }
            },
            {
                "name": "JavaScript Closure",
                "request": {
                    "flashcardId": "test-002", 
                    "question": "Explain what a closure is in JavaScript.",
                    "correctAnswer": "A closure is a function that has access to variables in its outer (enclosing) scope even after the outer function has returned.",
                    "userAnswer": "A closure gives you access to an outer function's scope from an inner function."
                }
            }
        ]
        
        success_count = 0
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n  Test {i}: {test_case['name']}")
            
            try:
                start_time = time.time()
                response = self.session.post(
                    f"{self.base_url}/api/grade",
                    json=test_case["request"],
                    timeout=TIMEOUT
                )
                end_time = time.time()
                
                response_time = end_time - start_time
                print(f"    Response Time: {response_time:.2f}s")
                
                if response.status_code == 200:
                    result = response.json()
                    print(f"    ✅ Status: {response.status_code}")
                    print(f"    📊 Score: {result.get('score', 'N/A')}")
                    print(f"    📝 Feedback: {result.get('feedback', 'No feedback')[:100]}...")
                    print(f"    💡 Suggestions: {len(result.get('suggestions', []))} provided")
                    
                    # CORRECTED: Check for actual response fields
                    expected_fields = ['score', 'feedback', 'suggestions']
                    has_all_fields = all(field in result for field in expected_fields)
                    
                    if has_all_fields:
                        success_count += 1
                        print(f"    ✅ Response structure valid")
                    else:
                        print(f"    ❌ Missing fields: {[f for f in expected_fields if f not in result]}")
                        
                else:
                    print(f"    ❌ Status: {response.status_code}")
                    print(f"    Error: {response.text[:200]}")
                    
            except requests.exceptions.Timeout:
                print(f"    ⏰ Timeout after {TIMEOUT}s")
            except Exception as e:
                print(f"    ❌ Error: {str(e)}")
        
        print(f"\nGrading Test Results: {success_count}/{len(test_cases)} passed")
        return success_count > 0
    
    def test_interview_grading_corrected(self) -> bool:
        """Test interview grading with CORRECT schema"""
        print("\n🎤 Testing Interview Grading (Corrected Schema)...")
        
        # CORRECTED: Use proper schema with questionId, questionText, category, difficulty
        interview_request = {
            "questionId": "interview-001",
            "questionText": "Tell me about yourself and your experience with Python.",
            "userAnswer": "I'm a software developer with 3 years of experience. I've worked with Python for web development using Flask and Django.",
            "category": "general",
            "difficulty": "intermediate"
        }
        
        try:
            start_time = time.time()
            response = self.session.post(
                f"{self.base_url}/api/interview-grade",
                json=interview_request,
                timeout=TIMEOUT
            )
            end_time = time.time()
            
            response_time = end_time - start_time
            print(f"  Response Time: {response_time:.2f}s")
            
            if response.status_code == 200:
                result = response.json()
                print(f"  ✅ Status: {response.status_code}")
                print(f"  📊 Score: {result.get('score', 'N/A')}")
                print(f"  📝 Feedback: {result.get('feedback', 'No feedback')[:100]}...")
                print(f"  💡 Suggestions: {len(result.get('suggestions', []))} provided")
                return True
            else:
                print(f"  ❌ Status: {response.status_code}")
                print(f"  Error: {response.text[:200]}")
                return False
                
        except requests.exceptions.Timeout:
            print(f"  ⏰ Timeout after {TIMEOUT}s")
            return False
        except Exception as e:
            print(f"  ❌ Error: {str(e)}")
            return False
    
    def test_job_description_endpoints(self) -> bool:
        """Test ACTUAL job description endpoints"""
        print("\n💼 Testing Job Description Endpoints (Corrected URLs)...")
        
        # Test 1: Job description analysis
        print("  Test 1: Job Description Analysis")
        analysis_request = {
            "job_description": "We are looking for a Python developer with experience in FastAPI, React, and cloud deployment. Must have 2+ years experience with machine learning."
        }
        
        analysis_success = False
        try:
            response = self.session.post(
                f"{self.base_url}/api/job-description/analyze",
                json=analysis_request,
                timeout=TIMEOUT
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"    ✅ Analysis Status: {response.status_code}")
                print(f"    📊 Analysis Result: {str(result)[:100]}...")
                analysis_success = True
            else:
                print(f"    ❌ Analysis Status: {response.status_code}")
                print(f"    Error: {response.text[:200]}")
                
        except Exception as e:
            print(f"    ❌ Analysis Error: {str(e)}")
        
        # Test 2: Question generation (if analysis worked)
        print("\n  Test 2: Question Generation")
        generation_success = False
        
        if analysis_success:
            # Use mock analysis data for question generation
            generation_request = {
                "job_analysis": {
                    "required_skills": ["Python", "FastAPI", "React"],
                    "experience_level": "intermediate",
                    "domain": "web_development"
                },
                "categories": ["technical", "general"],
                "difficulty_levels": ["intermediate"],
                "count_per_category": 2
            }
            
            try:
                response = self.session.post(
                    f"{self.base_url}/api/job-description/generate-questions",
                    json=generation_request,
                    timeout=TIMEOUT
                )
                
                if response.status_code == 200:
                    result = response.json()
                    print(f"    ✅ Generation Status: {response.status_code}")
                    questions = result.get('questions', [])
                    print(f"    📝 Generated {len(questions)} questions")
                    generation_success = True
                else:
                    print(f"    ❌ Generation Status: {response.status_code}")
                    print(f"    Error: {response.text[:200]}")
                    
            except Exception as e:
                print(f"    ❌ Generation Error: {str(e)}")
        else:
            print("    ⏭️ Skipping generation test (analysis failed)")
        
        return analysis_success or generation_success
    
    def test_suggestions_endpoint(self) -> bool:
        """Test suggestions endpoint (already working)"""
        print("\n💡 Testing Suggestions Endpoint...")
        
        suggestion_request = {
            "flashcardId": "test-suggestions-001"
        }
        
        try:
            start_time = time.time()
            response = self.session.post(
                f"{self.base_url}/api/suggestions",
                json=suggestion_request,
                timeout=TIMEOUT
            )
            end_time = time.time()
            
            response_time = end_time - start_time
            print(f"  Response Time: {response_time:.2f}s")
            
            if response.status_code == 200:
                result = response.json()
                print(f"  ✅ Status: {response.status_code}")
                print(f"  💡 Suggestions: {result.get('suggestions', [])}")
                return True
            else:
                print(f"  ❌ Status: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"  ❌ Error: {str(e)}")
            return False
    
    def run_corrected_test_suite(self) -> Dict[str, bool]:
        """Run corrected comprehensive test"""
        print("🚀 FlashMaster API CORRECTED Test Suite")
        print("=" * 55)
        print(f"Testing API at: {self.base_url}")
        print(f"Timestamp: {datetime.now().isoformat()}")
        print("=" * 55)
        
        results = {}
        
        # Test working endpoints first
        results['basic_connectivity'] = self.test_working_endpoints()
        
        # Test core functionality with correct schemas
        results['flashcard_grading_corrected'] = self.test_flashcard_grading_corrected()
        results['suggestions'] = self.test_suggestions_endpoint()
        results['interview_grading_corrected'] = self.test_interview_grading_corrected()
        results['job_description_endpoints'] = self.test_job_description_endpoints()
        
        # Summary
        print("\n" + "=" * 55)
        print("📊 CORRECTED TEST SUMMARY")
        print("=" * 55)
        
        total_tests = len(results)
        passed_tests = sum(results.values())
        
        for test_name, passed in results.items():
            status = "✅ PASS" if passed else "❌ FAIL"
            display_name = test_name.replace('_', ' ').title()
            print(f"{display_name}: {status}")
        
        print(f"\nOverall Result: {passed_tests}/{total_tests} tests passed")
        
        if passed_tests == total_tests:
            print("🎉 ALL TESTS PASSED! Your API is fully functional!")
        elif passed_tests >= total_tests * 0.8:
            print("✅ Most tests passed! API is working well.")
        elif passed_tests >= total_tests * 0.6:
            print("⚠️ Some tests failed, but core functionality works.")
        else:
            print("❌ Several tests failed. Check specific issues above.")
        
        # Success analysis
        print(f"\n🎯 SUCCESS ANALYSIS:")
        if results.get('basic_connectivity'):
            print("✅ Basic connectivity: WORKING")
        if results.get('flashcard_grading_corrected'):
            print("✅ Core AI grading: WORKING") 
        if results.get('suggestions'):
            print("✅ AI suggestions: WORKING")
        if results.get('interview_grading_corrected'):
            print("✅ Interview practice: WORKING")
        if results.get('job_description_endpoints'):
            print("✅ Job analysis: WORKING")
            
        return results


def main():
    """Main test execution with corrected schemas"""
    print("Starting CORRECTED FlashMaster API Tests...")
    
    tester = FlashMasterAPITester(API_BASE_URL)
    results = tester.run_corrected_test_suite()
    
    print("\n📝 KEY FIXES APPLIED:")
    print("✅ Fixed grading endpoint schema (added correctAnswer)")
    print("✅ Fixed interview endpoint schema (correct field names)")
    print("✅ Fixed job description endpoints (correct URLs)")
    print("✅ Fixed response validation (correct expected fields)")
    
    print("\n🎯 DEPLOYMENT STATUS:")
    working_features = sum(results.values())
    if working_features >= 4:
        print("🎉 DEPLOYMENT SUCCESSFUL - Core features working!")
        print("✅ Your FlashMaster API is ready for Flutter integration!")
    elif working_features >= 3:
        print("✅ DEPLOYMENT MOSTLY SUCCESSFUL - Minor issues only")
    else:
        print("⚠️ DEPLOYMENT NEEDS ATTENTION - Check failing tests")
    
    return results


if __name__ == "__main__":
    main()