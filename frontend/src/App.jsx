import { useState } from "react";
import "./App.css";

const terraformResources = [
  "VPC and public subnets",
  "Security groups and IAM roles",
  "ECR repositories for frontend and backend images",
  "ECS cluster and EC2 launch template",
  "Auto Scaling Group (ASG)",
  "ECS capacity provider",
  "Frontend and backend task definitions and services",
];

function App() {
  const [showDetails, setShowDetails] = useState(false);

  return (
    <div className="container">
      <div className="card">
        <p className="eyebrow">Docker · ECS · Terraform</p>
        <h1>Is Today&apos;s Target Completed?</h1>
        <p className="subtitle">
          Check the application deployment and the infrastructure managed with
          Terraform.
        </p>

        <button
          className="see-button"
          type="button"
          aria-expanded={showDetails}
          aria-controls="completion-details"
          onClick={() => setShowDetails((isVisible) => !isVisible)}
        >
          {showDetails ? "Hide" : "See"}
        </button>

        {showDetails && (
          <section
            className="completion-details"
            id="completion-details"
            aria-live="polite"
          >
            <div className="completion-message">
              <span className="checkmark" aria-hidden="true">
                ✓
              </span>
              <p>Yes, today&apos;s target is completed!</p>
            </div>

            <h2>Configured through Terraform</h2>
            <ul>
              {terraformResources.map((resource) => (
                <li key={resource}>{resource}</li>
              ))}
            </ul>
          </section>
        )}
      </div>
    </div>
  );
}

export default App;