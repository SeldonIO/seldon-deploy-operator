# Publishing and Using Images

## Certified Images - Notes

You can get to certified image listings through RH access portal. Creds https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=pbdteciyqnp3rsxpcrkaxevftm&v=po7kyvksukhlrsurwmygolab3a

Here is the old operator image https://connect.redhat.com/project/4805411/view

If you go to Settings from that page then you see how to pull the image.

Passwords for uploading in https://start.1password.com/open/i?a=SSGQBEYWPRHN7GYLNPQYAOU7QA&h=team-seldon.1password.com&i=f4hgces2dvxqirpcsir2uiqbe4&v=65l42gglwnfjheao6fu4pmxeti

Under images there is a 'push image manually' button that takes you to credentials for pushing.

The script that was used to push it was https://github.com/SeldonIO/seldon-deploy-operator/blob/8531183514393f0040f4856ff7da4507aa2841c5/Makefile#L15

A checklist is run on the redhat side. That is shown under 'Checklist' in the UI. licenses are required in Docker images.

Approval is also needed for new projects. There's a 'Obtain distribution approval from Red Hat' step under checklist.

# List of Images

Bundle (packages the catalog listing)
Operator (runs the helm operator to manage SeldonDeploy CRD)
Deploy Server (what we normally call Deploy)
Batchjobs processor image
Batchjobs mc image
Request logger (published with core?)
Kubectl
Loadtester
Alibi detect

See manager.yaml. Any images used in helm chart have to be referenced there by RELATED_IMAGE_

The RELATED_IMAGE_ will always be replaced, irrespective of what's in the values file. This is for handling airgapped.

There's separate manifests for certified. This is because RCR images don't work on KIND since you have to log in to pull. (Verify this?)

So should have two make targets for each of the above (either here or in Deploy repo), one for RCR and one for docker or quay.

The table below has the make targets for the images. Each should have two, one being certified.

Note the bundle image needs all other images to be published (not approved) in order to pass.

There is a make target for pushing each image. They don't all follow the same versioning and are in different git repos.

Go through each of the below and check whether the version deploy references is published in Red Hat Container Registry if changed (links further down).

Versions referenced in the below table and in the make targets *should checked against the deploy values and be updated if needed* per-release.

| Image      | Git Repo   | Make Targets                                        |  Status |
| ---------- | ---------- | --------------------------------------------------- | ----------- |
| Bundle     | here       |update_openshift_cert, build_push_cert               | 1.2.0 pending  |
| Operator   | here       |docker-build, redhat-image-scan                      | 1.2.0 pending |
| Deploy     | deploy     |build_image_redhat & redhat-image-scan  | 1.2.0 pending |
| Batch Proc | here       |build-batch-proc-image,redhat-batch-proc-image-scan  | 1.6.0 pending |
| Batch mc   | here       |build-minio-image, redhat-minio-client-image-scan    | 1.0 published |
| Req log    | core       |under components/seldon-request-logger      | [1.7.0 published](https://connect.redhat.com/project/3993051/images) |
| kubectl    | here       |build-kubectl-image, redhat-kubectl-image-scan       | hasn't changed not used, no need to repub |
| loadtest   | deploy     |deploy repo, tools/images/loadtest-image             | hasn't changed, 0.1 still latest |
| alibi      | core       |under components/alibi-detect-server                 | [using 1.7.0 (published) even though deploy released against 1.7.0](https://connect.redhat.com/project/3993461/images)   |

There are additional make targets for pushing to RCR.

BUNDLE PROJECT IS https://connect.redhat.com/project/5892521/images

DEPLOY OPERATOR IS - https://connect.redhat.com/project/4805411/images

DEPLOY IMAGE IS - https://connect.redhat.com/project/4805801/images

MINIO IMAGE IS - https://connect.redhat.com/project/5937511/images

BATCH PROC IS - https://connect.redhat.com/project/5937521/images

CERT IMAGE NAMES IN packagemanifests-certified.sh

