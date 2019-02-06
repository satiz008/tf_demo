# Let's create the GKE cluster! This one's pretty complicated so buckle up.

# This is another example of the random provider. Here we're using it to pick a
# zone in us-central1 at random.
resource "random_shuffle" "zone" {
  input = ["us-central1-a", "us-central1-b", "us-central1-c", "us-central1-f"]

  # Seeding the RNG is technically optional but while I was building this I
  # found that it only ever picked `us-central-1c` unless I seeded it. Here
  # we're using the ID of the project as a seed because it is unique to the
  # project but will not change, thereby guaranteeing stability of the results.
  seed = "${google_project.project.id}"
}

# First we create the cluster. If you're wondering where all the sizing details
# are, they're below in the `google_container_node_pool` resource. We'll get
# back to that in a minute.
#
# One thing to note here is the name of the resource ("gke") is only used
# internally, for instance when you're referencing the resource (eg
# `google_container_cluster.gke.id`). The actual created resource won't know
# about it, and in fact you can specify the name for that in the resource
# itself.
#
# Finally, there are many, many other options available. The resource below
# replicates what the Hipster Shop README creates. If you want to see what else
# is possible, check out the docs: https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "gke" {
  project = "${google_project.project.id}"

  # ... and here's how you specify the name
  name = "stackdriver-sandbox"

  # next we set the zone by grabbing the result of the random_shuffle above. It
  # returns a list so we have to pull the first element off. If you're looking
  # at this and thinking "huh terraform syntax looks a clunky" you are NOT WRONG
  zone = "${element(random_shuffle.zone.result, 0)}"

  # here we're using an embedded resource to define the node pool. Another
  # option would be to create the node pool as a separate resource and link it
  # to this cluster. There are tradeoffs to each approach.
  #
  # The embedded resource is convenient but if you change it you have to tear
  # down the entire cluster and rebuild it. A separate resource could be
  # modified independent of the cluster without the cluster needing to be torn
  # down.
  #
  # For this particular case we're not going to be modifying the node pool once
  # it's deployed, so it makes sense to accept the tradeoff for the convenience
  # of having it inline.
  #
  # Many of the paramaters below are self-explanatory so I'll only call out
  # interesting things.
  node_pool {
    initial_node_count = 5

    # this stanza could be left off and we'd just always have five nodes
    autoscaling {
      min_node_count = 3
      max_node_count = 10
    }

    # this stanza could be omitted and both would default to false
    management {
      auto_repair  = true
      auto_upgrade = true
    }
  }
}
