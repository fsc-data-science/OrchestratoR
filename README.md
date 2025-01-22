# OrchestratoR

An R-based orchestration system that coordinates AI agents to produce structured analytical reports through a modular set-based architecture.

## System Overview

The OrchestratoR system transforms analytical requests into structured HTML reports through a carefully orchestrated process of set creation, verification, and assembly. At its core, the system uses a modular approach where each analysis component is created as a verified, self-contained set before being combined into the final report.

### Core Components

#### Analysis Sets
The fundamental unit of analysis in the system is a "set" - a JSON-structured file that contains:
- A descriptive heading
- Key findings as bullet points
- Verified SQL queries for data acquisition
- Validated R code for analysis and visualization
- Metadata for organization and tracking

Sets are created sequentially with numerical prefixes (e.g., "01-overview.json", "02-detail.json") to maintain logical order in the final report.

#### AI Agents
The system integrates specialized AI agents, each with specific capabilities:
- Expert SQL generators for different blockchain ecosystems
- Analysis strategists for structuring investigations
- Data science experts for methodology validation

Each agent operates through a structured API interface and maintains its own context and expertise domain.

### Workflow Architecture

#### 1. Request Processing
When the system receives an analytical request, it:
- Creates a dedicated directory for the analysis
- Initializes a template structure
- Begins coordinating with appropriate agents

#### 2. Set Creation Process
Each analysis set follows a strict verification workflow:
1. SQL Generation: Coordinates with expert agents to create appropriate queries
2. Data Validation: Verifies query execution and data structure
3. Analysis Creation: Develops and tests analytical code
4. Set Assembly: Combines verified components into a structured set
5. Format Verification: Confirms set structure and compatibility

#### 3. Report Assembly
After all sets are created and verified, the system:
- Identifies all relevant JSON set files
- Orders them by numerical prefix
- Combines them into a cohesive report structure
- Generates the final HTML output

### Core Functions

#### Agent Coordination
- Manages communication with specialized AI agents
- Ensures proper formatting of agent requests
- Validates agent responses before implementation

#### Code Execution
- Runs and verifies SQL queries in Snowflake
- Executes R code for analysis and visualization
- Maintains execution environment consistency

#### Set Management
- Creates numbered JSON set files
- Verifies set structure and content
- Manages set interdependencies

#### Report Generation
- Combines verified sets in proper order
- Assembles final report structure
- Handles HTML generation

#### Set Structure
```json
{
  "sets": [{
    "heading": "Analysis Section",
    "bullets": ["Key finding 1", "Key finding 2"],
    "sql_chunk": {
      "object_name": "result_name",
      "query": "Verified SQL query"
    },
    "analysis_chunks": [{
      "object_name": "analysis_name",
      "code": "Verified R code"
    }]
  }],
  "metadata": {
    "title": "Analysis Title",
    "date": "2025-01-22",
    "directory": "analysis_dir"
  }
}
```
