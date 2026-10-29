# Publish the first version

The folder is ready for an initial commit to a new repository, for example pnl-reconciliation-dbt. No remote repository is created or published by this package.

1. Keep the README, docs, model files, seeds, macros, tests, scripts, requirements and GitHub workflow.
2. The .gitignore excludes the local database, logs, environments and dbt build artifacts.
3. Run the demo command in the README before committing.
4. Create an empty GitHub repository and push the folder contents on main.
5. Add a short portfolio entry linking to the new README. Both the PDF and images use relative paths within the repository.

Suggested repository description:

Component cost reconciliation in dbt: commercial products, versioned BOMs, warehouse actuals and period costs, with explicit grains, conformed dimensions and synthetic examples.

## README PDF and visuals

The PDF prints the README content; it is not a different case-study narrative.

To regenerate committed visuals and PDF:

    python -m pip install -r requirements-docs.txt
    python scripts/render_readme.py

The diagrams illustrate the documented synthetic shared-component example. Run the demo first when fixtures or calculations change, and update the README and diagrams together.

## Scope of evidence

The public verification report records local dbt results and deliberate failure checks. A hosted GitHub Actions result will exist only after the workflow runs in the published repository.

The package does not include the private interview note, unrelated models, binary databases or the original full archive.
