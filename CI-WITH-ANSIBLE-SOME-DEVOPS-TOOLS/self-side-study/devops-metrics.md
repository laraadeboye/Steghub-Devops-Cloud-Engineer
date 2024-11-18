# DevOps Metrics Every Leader Should Track

Devops is concerned about being able to ship out quality code as fast as possible. Though, this is a valid aspiration, we must be careful not to break anything while moving fast. As a DevOps leader, tracking the right metrics is crucial for ensuring the success of your development and operations teams. The following highlights key metrics that should be tracked:

1. **Deployment Frequency**:

Measures how often new releases are deployed to production. It is imperative to reduce the size  
Measures how often new releases are deployed to production.  It is imperative to reduce the size of deployment an do smaller deployments as often as possible

2. **Lead Time for Changes**:

The time it takes for a code commit to reach production. If start a new work item, how long on  average would it take to get to production?
Shorter lead times suggest a more streamlined development process.

3. **Change Failure Rate**:

The percentage of changes that result in failures in production. Lower rates indicate better quality control and testing practices.

4. **Mean Time to Recovery (MTTR)**:
The average time taken to recover from a failure in production. Faster recovery times reflect effective incident management processes. It is usually measured in hours - business hours

5. **Mean Time to Detect (MTTD)**:

Measures how quickly issues are identified in production. Shorter detection times lead to quicker resolutions and less downtime. We definitely do not want to have a najor partial or complete system outage and not know about it!
When we have a robust application monitoring and observability tools in place, we will be able to detect issues quickly and in event, we must fix them early!

6. **Failed Deployments / Mean Time To Failure**:

We must track how often our deployments cause a major outage for the users. We dont want to get to the point of having to reverse a failed deployment but we must plan for it. It could be seen as tracking **Mean Time To Failure**

7. **Service Level Agreements (SLAs)**:

Metrics that measure the performance of services against agreed-upon standards, ensuring that teams meet customer expectations.


8. **Infrastructure Cost Efficiency**:
Evaluates the cost-effectiveness of infrastructure usage, helping teams optimize resource allocation and reduce waste.

9. **Test Automation Coverage**:
The percentage of tests that are automated versus manual testing. Higher automation coverage can lead to faster testing cycles and increased reliability.

10. **Percentage of passed automated tests**:

To increase velocity, the team should use unit and functional testing extensively. Tracking automated tests helps us to know how often code changes break tests.

11. **Defect escape rate**:

Used to track how often defects make it to production. We must know how many software defects are found in production vs QA.

12. **Availability**:
As Devops engineers, we do not want our application to be down. As part of sheduled maintenance, depending on the application and how it is deployed, we may have a little downtime. Some companies like google have status pages to track availability of their application.


13. **Code Quality Metrics**:
Metrics such as code complexity, maintainability, and code review statistics help ensure high-quality code 
is being produced.

14. **Customer Satisfaction / Customer tickets**:

Measuring user satisfaction through surveys or feedback helps assess how well the delivered software meets user needs.
Customer support tickets and feedbacks  are a good indicator of application quality and performance problems. We do not want customers reporting bugs and having problems with our software!


15. **Team Satisfaction**:

Regularly gauging team morale and job satisfaction can provide insights into team dynamics and help identify areas for improvement.

16. **Incident Volume**:

Tracking the number of incidents over time helps identify trends and areas where improvements can be made in stability and reliability.

17. **Pipeline Efficiency**:
Measures the efficiency of the CI/CD pipeline, including build times, test durations, and deployment times, allowing for continuous improvement.

18. **Error rates**:

Tracking error rates is an indicator of quality problems and ongoing performance and uptime related isssues. Errors, in software development is known as exceptions and proper exception handling is crucial. They include:

  - Bugs: Exceptions thrown in the code after deployment
  - Production Issues: Database connection issues, query timeouts


19. **Application usage & traffic**:
This metric helps us to see the number of transactions or users accessing our system. No traffic or giant spike in traffic can be indicative of different issues. For instance, excessive spike in traffic may indicate DDOS attack

20. **Application performance metrics**:
It is imperative to monitor application performance such as load time, response time, throughput using monitoring tools like **Retrace**. **DataDog**, **New Relic** or **AppDynamics** to look for changes in overall application performance and establish bench marks to know when things deviate from the norm.

## Additional Devops Metrics

1. **Change Volume**:
Measures the total number of changes made in a specific time frame, helping teams understand their development activity.

2. **Code Churn**:
The percentage of a developer's own code representing recent edits. High churn may indicate indecision or issues in requirements.

3. **Technical Debt**:
A measure of how much "quick and dirty" work has been done that may need to be refactored later, affecting long-term maintenance.

4. **User Engagement Metrics**:
Metrics such as active users, session duration, and user retention can provide insights into how well the software meets user needs.

5. **Security Metrics**:
Metrics related to vulnerabilities found, security incidents, and compliance with security policies help assess the security posture of applications.

6. **Cost Metrics**:
Tracking costs associated with infrastructure usage, development resources, and operational expenses can help in budgeting and financial planning.

7. **Time to Market**:
Measures how long it takes to go from ideation to deployment, providing insight into overall efficiency in delivering features.



