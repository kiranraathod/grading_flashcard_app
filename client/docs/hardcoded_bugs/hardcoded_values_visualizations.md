# Visual Analysis of Hardcoded Values in FlashMaster Application

## Distribution of Hardcoded Values by Category

```mermaid
pie title Distribution of 87+ Hardcoded Values by Category
    "Text Content" : 35
    "Numerical Constants" : 20
    "Visual Styling" : 18
    "Configuration Values" : 8
    "Default Data" : 6
```

## Locations of Hardcoded Values in Application Architecture

```mermaid
flowchart TD
    subgraph Client["Flutter Client Application"]
        UI["UI Layer (Screens & Widgets)"]
        BLoC["BLoC State Management"]
        Models["Data Models"]
        Services["Client Services"]
        Utils["Utilities"]
    end
    
    subgraph Server["Python FastAPI Server"]
        Routes["API Routes"]
        Controllers["Controllers"]
        Services2["Server Services"]
        LLM["LLM Integration"]
    end
    
    UI --> |"35 Text Content\n11 Numerical Constants\n15 Visual Styling"| HC1["Hardcoded Values"]
    Models --> |"6 Default Data"| HC2["Hardcoded Values"]
    Services --> |"5 Configuration Values"| HC3["Hardcoded Values"]
    Utils --> |"9 Numerical Constants\n3 Visual Styling"| HC4["Hardcoded Values"]
    Services2 --> |"3 Configuration Values"| HC5["Hardcoded Values"]
```

## Hardcoded Values by File Distribution

```mermaid
graph TD
    subgraph Files["Top Files with Hardcoded Values"]
        HS["home_screen.dart\n21+ instances"]
        IQS["interview_questions_screen.dart\n17+ instances"]
        CIQS["create_interview_question_screen.dart\n15+ instances"]
        DS["design_system.dart\n9+ instances"]
        CFS["create_flashcard_screen.dart\n8+ instances"]
        CM["category_mapper.dart\n7+ instances"]
        FS["flashcard_service.dart\n6+ instances"]
        AS["api_service.dart\n5+ instances"]
    end
```

## Hardcoded Values by Impact Category

```mermaid
graph LR
    subgraph Types["Impact Categories"]
        L["Localization Issues\n40+ instances"]
        R["Responsive Design Issues\n25+ instances"]
        C["Configuration Management\n12+ instances"]
        V["Visual Consistency\n10+ instances"]
    end
    
    L --> T["Text Strings\nScreen Titles\nButton Labels\nPlaceholders"]
    R --> D["Fixed Dimensions\nHardcoded Spacing\nStatic Layouts"]
    C --> E["API Endpoints\nTimeouts\nRetry Logic"]
    V --> S["Color Values\nFont Sizes\nBorder Radius"]
```

## Implementation Priority Map

```mermaid
quadrantChart
    title Implementation Priority for Fixing Hardcoded Values
    x-axis Low Impact --> High Impact
    y-axis Low Effort --> High Effort
    quadrant-1 "Quick Wins"
    quadrant-2 "Major Projects"
    quadrant-3 "Fill-ins"
    quadrant-4 "Thankless Tasks"
    "Configuration Values": [0.9, 0.3]
    "Text Content": [0.8, 0.7]
    "Visual Styling": [0.5, 0.4]
    "Numerical Constants": [0.7, 0.5]
    "Default Data": [0.4, 0.6]
```

## Category Distribution Across Application Components

```mermaid
sankey-beta
    Hardcoded Values,UI Components,35
    Hardcoded Values,Services,8
    Hardcoded Values,Models,6
    Hardcoded Values,Utilities,20
    Hardcoded Values,API,8
    UI Components,Text Content,25
    UI Components,Visual Styling,10
    Services,Configuration,5
    Services,Visual Styling,3
    Models,Default Data,6
    Utilities,Numerical Constants,15
    Utilities,Visual Styling,5
    API,Configuration,3
    API,Default Data,5
```

The diagrams above visually represent the distribution and impact of hardcoded values throughout the FlashMaster application. The majority of hardcoded values are concentrated in the UI layer, particularly in text content, which presents significant challenges for localization. The implementation priority chart suggests focusing first on configuration values as they are high-impact but relatively low-effort to fix.
