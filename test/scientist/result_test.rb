describe Scientist::Result do
  before do
    @experiment = Scientist::Experiment.new "experiment"
  end

  it "is immutable" do
    control = Scientist::Observation.new("control", @experiment)
    candidate = Scientist::Observation.new("candidate", @experiment)

    result = Scientist::Result.new @experiment, [control, candidate], control
    assert result.frozen?
  end

  it "evaluates its observations" do
    a = Scientist::Observation.new("a", @experiment) { 1 }.conduct
    b = Scientist::Observation.new("b", @experiment) { 1 }.conduct

    assert a.equivalent_to?(b)

    result = Scientist::Result.new @experiment, [a, b], a
    assert result.matched?
    refute result.mismatched?
    assert_equal [], result.mismatched

    x = Scientist::Observation.new("x", @experiment) { 1 }.conduct
    y = Scientist::Observation.new("y", @experiment) { 2 }.conduct
    z = Scientist::Observation.new("z", @experiment) { 3 }.conduct

    result = Scientist::Result.new @experiment, [x, y, z], x
    refute result.matched?
    assert result.mismatched?
    assert_equal [y, z], result.mismatched
  end

  it "has no mismatches if there is only a control observation" do
    a = Scientist::Observation.new("a", @experiment) { 1 }.conduct
    result = Scientist::Result.new @experiment, [a], a
    assert result.matched?
  end

  it "evaluates observations using the experiment's compare block" do
    a = Scientist::Observation.new("a", @experiment) { "1" }.conduct
    b = Scientist::Observation.new("b", @experiment) { 1 }.conduct

    @experiment.compare { |x, y| x == y.to_s }

    result = Scientist::Result.new @experiment, [a, b], a

    assert result.matched?, result.mismatched
  end

  it "does not ignore any mismatches when nothing's ignored" do
    x = Scientist::Observation.new("x", @experiment) { 1 }.conduct
    y = Scientist::Observation.new("y", @experiment) { 2 }.conduct

    result = Scientist::Result.new @experiment, [x, y], x

    assert result.mismatched?
    refute result.ignored?
  end

  it "uses the experiment's ignore block to ignore mismatched observations" do
    x = Scientist::Observation.new("x", @experiment) { 1 }.conduct
    y = Scientist::Observation.new("y", @experiment) { 2 }.conduct
    called = false
    @experiment.ignore { called = true }

    result = Scientist::Result.new @experiment, [x, y], x

    refute result.mismatched?
    refute result.matched?
    assert result.ignored?
    assert_equal [], result.mismatched
    assert_equal [y], result.ignored
    assert called
  end

  it "partitions observations into mismatched and ignored when applicable" do
    x = Scientist::Observation.new("x", @experiment) { :x }.conduct
    y = Scientist::Observation.new("y", @experiment) { :y }.conduct
    z = Scientist::Observation.new("z", @experiment) { :z }.conduct

    @experiment.ignore { |control, candidate| candidate == :y }

    result = Scientist::Result.new @experiment, [x, y, z], x

    assert result.mismatched?
    assert result.ignored?
    assert_equal [y], result.ignored
    assert_equal [z], result.mismatched
  end

  it "knows the experiment's name" do
    a = Scientist::Observation.new("a", @experiment) { 1 }.conduct
    b = Scientist::Observation.new("b", @experiment) { 1 }.conduct
    result = Scientist::Result.new @experiment, [a, b], a

    assert_equal @experiment.name, result.experiment_name
  end

  it "has the context from an experiment" do
    @experiment.context :foo => :bar
    a = Scientist::Observation.new("a", @experiment) { 1 }.conduct
    b = Scientist::Observation.new("b", @experiment) { 1 }.conduct
    result = Scientist::Result.new @experiment, [a, b], a

    assert_equal({:foo => :bar}, result.context)
  end

end
